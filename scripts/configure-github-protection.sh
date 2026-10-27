#!/usr/bin/env bash
# Owner-only: configure PR-based contribution protections on main.
# Requires gh auth login with repository administration permission.
set -euo pipefail
repo="Itsnicbtw/IDENTOS"
command -v gh >/dev/null || { echo 'Install GitHub CLI first' >&2; exit 1; }
gh auth status >/dev/null
if gh api "repos/$repo/rulesets" --jq '.[] | select(.name=="IDENT OS protected main") | .id' | grep -q .; then
  echo 'IDENT OS protected main ruleset already exists. Edit it in Settings > Rules > Rulesets.'
  exit 0
fi
cat <<'JSON' | gh api --method POST "repos/Itsnicbtw/IDENTOS/rulesets" --input -
{
  "name": "IDENT OS protected main",
  "target": "branch",
  "enforcement": "active",
  "conditions": {"ref_name": {"include": ["refs/heads/main"], "exclude": []}},
  "rules": [
    {"type": "deletion"},
    {"type": "non_fast_forward"},
    {"type": "pull_request", "parameters": {
      "dismiss_stale_reviews_on_push": true,
      "require_code_owner_review": false,
      "require_last_push_approval": false,
      "required_approving_review_count": 1,
      "required_review_thread_resolution": true
    }},
    {"type": "required_status_checks", "parameters": {
      "strict_required_status_checks_policy": true,
      "do_not_enforce_on_create": false,
      "required_status_checks": [{"context": "build-and-boot"}]
    }}
  ]
}
JSON
echo 'Ruleset created. Public contributors can propose PRs, but main requires CI and review.'
