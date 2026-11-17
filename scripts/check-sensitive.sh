#!/usr/bin/env bash
# Fails if the repository contains AWS identifiers other than the documented placeholders.
# Prints file:line only, never the matched value.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

PLACEHOLDER_ACCOUNT="111111111111"
status=0

scan() {
  local description="$1" pattern="$2" allow="$3"
  local hits
  hits="$(git ls-files -z --cached --others --exclude-standard \
    | xargs -0 grep -nIoE "${pattern}" -- 2>/dev/null \
    | grep -v -- '.terraform.lock.hcl:' \
    | grep -vE ":(${allow})$" || true)"
  if [[ -n "${hits}" ]]; then
    echo "ERROR: ${description}:"
    cut -d: -f1,2 <<<"${hits}" | sort -u | sed 's/^/  /'
    status=1
  fi
}

scan "AWS account ID other than ${PLACEHOLDER_ACCOUNT}" '(arn:aws[a-z-]*:[a-z0-9-]*:[a-z0-9-]*:|account[_-]?id["'"'"' :=]+)[0-9]{12}' ".*${PLACEHOLDER_ACCOUNT}"
scan "Bare 12-digit number (possible AWS account ID)" '\b[0-9]{12}\b' "${PLACEHOLDER_ACCOUNT}|000000000000"
scan "VPC / subnet / security group ID other than placeholders" '\b(vpc|subnet|sg)-[0-9a-f]{8,17}\b' '(vpc|subnet|sg)-0123456789abcdef[0-9]'
scan "KMS key ID other than the zero UUID" 'key/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' 'key/00000000-0000-0000-0000-000000000000'
scan "AWS SSO reserved role ARN" 'AWSReservedSSO_[A-Za-z0-9_-]+' '^$'
scan "AWS access key ID" '\b(AKIA|ASIA)[0-9A-Z]{16}\b' '^$'

if [[ "${status}" -eq 0 ]]; then
  echo "OK: no real AWS identifiers found"
fi
exit "${status}"
