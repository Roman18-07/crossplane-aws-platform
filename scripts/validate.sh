#!/usr/bin/env bash
# Offline validation of the Helm charts, rendered Crossplane manifests and Argo CD manifests.
# Requires: helm, kubeconform, python3 (PyYAML), curl. Never talks to a cluster or to AWS.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="${BUILD_DIR:-${ROOT}/.build}"
RENDER="${BUILD}/rendered"
SCHEMAS="${BUILD}/schemas"
K8S_VERSION="${K8S_VERSION:-1.33.0}"
OPENAPI2JSONSCHEMA_URL="https://raw.githubusercontent.com/yannh/kubeconform/v0.7.0/scripts/openapi2jsonschema.py"

cd "${ROOT}"
rm -rf "${RENDER}"
mkdir -p "${RENDER}" "${SCHEMAS}"

# Versions are read from the charts so that validation always matches what is deployed.
CROSSPLANE_VERSION="v$(awk '/- name: crossplane/{f=1} f && /version:/{gsub(/"/,"",$2); print $2; exit}' platform-applications/profiles/crossplane-adopted/Chart.yaml)"
PROVIDER_AWS_VERSION="$(sed -n 's/^package: .*:\(v[0-9.]*\)$/\1/p' platform-applications/profiles/crossplane-provider-aws-s3-adopted/values.yaml)"
echo "Crossplane ${CROSSPLANE_VERSION}, provider-aws ${PROVIDER_AWS_VERSION}, Kubernetes ${K8S_VERSION}"

for f in platform-applications/profiles/crossplane-provider-aws-*-adopted/values.yaml; do
  if ! grep -q ":${PROVIDER_AWS_VERSION}$" "${f}"; then
    echo "ERROR: ${f} does not pin provider version ${PROVIDER_AWS_VERSION}" >&2
    exit 1
  fi
done

echo "==> helm dependency build"
helm repo add crossplane-stable https://charts.crossplane.io/stable --force-update >/dev/null
helm dependency build platform-applications/profiles/crossplane-adopted >/dev/null

echo "==> helm lint"
for chart in platform-applications/profiles/*/ applications/profiles/*/; do
  helm lint --strict --quiet "${chart}"
done

echo "==> helm template: platform services"
for svc in platform-applications/services/*/; do
  name="$(basename "${svc}")"
  profile="$(awk '/^profile:/{print $2}' "${svc}service.yaml")"
  namespace="$(awk '/^namespace:/{print $2}' "${svc}service.yaml")"
  helm template "${name}" "platform-applications/profiles/${profile}" -n "${namespace}" \
    -f platform-applications/services/service.yaml -f "${svc}service.yaml" > "${RENDER}/platform-${name}.yaml"
done
for chart in platform-applications/profiles/crossplane-provider-aws-*-adopted/; do
  helm template defaults "${chart}" > "${RENDER}/defaults-$(basename "${chart}").yaml"
done

echo "==> helm template: application services"
for svc in applications/services/*/; do
  name="$(basename "${svc}")"
  profile="$(awk '/^profile:/{print $2}' "${svc}service.yaml")"
  args=(-f applications/services/service.yaml -f "${svc}service.yaml")
  [[ -f "${svc}infrastructure.yaml" ]] && args+=(-f "${svc}infrastructure.yaml")
  helm template "${name}" "applications/profiles/${profile}" -n "${name}-a" "${args[@]}" > "${RENDER}/app-${name}.yaml"
  helm template "${name}" "applications/profiles/${profile}" -n "${name}-a" "${args[@]}" \
    --set s3.enabled=true --set rds.enabled=true > "${RENDER}/app-${name}-all-enabled.yaml"
done

echo "==> helm template: examples"
for example in examples/*.yaml; do
  helm template example applications/profiles/aws-service-resources-v1 -n example \
    -f "${example}" > "${RENDER}/example-$(basename "${example}")"
done

echo "==> generate JSON schemas from pinned CRDs"
if [[ ! -f "${SCHEMAS}/.${CROSSPLANE_VERSION}-${PROVIDER_AWS_VERSION}" ]]; then
  rm -rf "${SCHEMAS:?}"/*
  curl -fsSL -o "${BUILD}/openapi2jsonschema.py" "${OPENAPI2JSONSCHEMA_URL}"
  crds=(
    "https://raw.githubusercontent.com/crossplane/crossplane/${CROSSPLANE_VERSION}/cluster/crds/pkg.crossplane.io_providers.yaml"
    "https://raw.githubusercontent.com/crossplane/crossplane/${CROSSPLANE_VERSION}/cluster/crds/pkg.crossplane.io_deploymentruntimeconfigs.yaml"
  )
  for crd in aws.upbound.io_providerconfigs \
             s3.aws.upbound.io_buckets s3.aws.upbound.io_bucketacls s3.aws.upbound.io_bucketpublicaccessblocks \
             rds.aws.upbound.io_instances rds.aws.upbound.io_subnetgroups \
             ec2.aws.upbound.io_securitygroups ec2.aws.upbound.io_securitygrouprules \
             kms.aws.upbound.io_keys kms.aws.upbound.io_aliases \
             cloudwatch.aws.upbound.io_metricalarms; do
    crds+=("https://raw.githubusercontent.com/crossplane-contrib/provider-upjet-aws/${PROVIDER_AWS_VERSION}/package/crds/${crd}.yaml")
  done
  mkdir -p "${BUILD}/crds"
  for url in "${crds[@]}"; do
    curl -fsSL -o "${BUILD}/crds/$(basename "${url}")" "${url}"
  done
  (cd "${SCHEMAS}" && FILENAME_FORMAT='{fullgroup}-{kind}-{version}' python3 "${BUILD}/openapi2jsonschema.py" "${BUILD}"/crds/*.yaml >/dev/null)
  touch "${SCHEMAS}/.${CROSSPLANE_VERSION}-${PROVIDER_AWS_VERSION}"
fi

echo "==> kubeconform"
kubeconform -strict -summary -output text \
  -kubernetes-version "${K8S_VERSION}" \
  -schema-location default \
  -schema-location "${SCHEMAS}/{{.Group}}-{{.ResourceKind}}-{{.ResourceAPIVersion}}.json" \
  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
  "${RENDER}"/*.yaml argocd/*.yaml

echo "==> provider wiring"
python3 - "${RENDER}" <<'PY'
import glob, sys, yaml

docs = []
for path in glob.glob(f"{sys.argv[1]}/*.yaml"):
    docs += [(path, d) for d in yaml.safe_load_all(open(path)) if d]

provider_configs = {d["metadata"]["name"] for _, d in docs if d["kind"] == "ProviderConfig"}
errors = []
for path, d in docs:
    if d["apiVersion"].endswith(".aws.upbound.io/v1beta1"):
        ref = d["spec"].get("providerConfigRef", {}).get("name")
        if ref not in provider_configs:
            errors.append(f"{path}: {d['kind']}/{d['metadata']['name']} references unknown ProviderConfig '{ref}'")
    if d["kind"] == "DeploymentRuntimeConfig" and "defaults" not in path:
        sa = d["spec"]["serviceAccountTemplate"]["metadata"]
        if not sa["name"].startswith("crossplane-provider-aws-"):
            errors.append(f"{path}: ServiceAccount '{sa['name']}' does not match the IRSA trust pattern crossplane-provider-aws-*")
        if "eks.amazonaws.com/role-arn" not in (sa.get("annotations") or {}):
            errors.append(f"{path}: ServiceAccount '{sa['name']}' has no IRSA role annotation")
if errors:
    print("\n".join(errors)); sys.exit(1)
print(f"OK: {len(provider_configs)} ProviderConfigs, all managed resources reference an existing ProviderConfig")
PY

echo "All checks passed."
