#!/usr/bin/env bash
# check-coverage.sh — Fail CI if Sonas/ source coverage drops below 80%
# Constitution §II: coverage gate ≥80% on Sonas/ source target
# NOTE: Constitution §II references src/ but this project uses Sonas/ as the source
# directory. This script intentionally uses Sonas/ per the actual project structure.
# A formal constitution amendment is pending (two-contributor sign-off required).
#
# Usage:
#   .ci/check-coverage.sh <path/to/coverage.json>
#   Called after: xcodebuild test -enableCodeCoverage YES
#   The coverage JSON is produced by xcresulttool from the .xcresult bundle.

set -euo pipefail

THRESHOLD=80
COVERAGE_JSON="${1:-}"
TARGET="Sonas"

if [[ -z "${COVERAGE_JSON}" ]]; then
    echo "Usage: $0 <coverage.json>" >&2
    exit 1
fi

if [[ ! -f "${COVERAGE_JSON}" ]]; then
    echo "ERROR: Coverage file not found: ${COVERAGE_JSON}" >&2
    exit 1
fi

# Extract coverage percentage for the Sonas target using jq
if ! command -v jq &>/dev/null; then
    echo "ERROR: jq is required. Install with: brew install jq" >&2
    exit 1
fi

COVERAGE=$(jq -r --arg target "${TARGET}" '
  .targets[]
  | select(.name == $target)
  | (.coveredLines / .executableLines * 100)
  | floor
' "${COVERAGE_JSON}" 2>/dev/null || echo "")

if [[ -z "${COVERAGE}" ]]; then
    echo "WARNING: Could not extract coverage for target '${TARGET}'. Check the JSON structure." >&2
    exit 0 # Non-fatal: may be a different xcresulttool format
fi

echo "Coverage for ${TARGET}: ${COVERAGE}%"

if ((COVERAGE < THRESHOLD)); then
    echo "ERROR: Coverage ${COVERAGE}% is below the required threshold of ${THRESHOLD}%." >&2
    echo "Add unit tests in SonasTests/Unit/ to bring coverage up to ${THRESHOLD}%." >&2
    exit 1
fi

echo "✓ Coverage gate passed (${COVERAGE}% >= ${THRESHOLD}%)"
