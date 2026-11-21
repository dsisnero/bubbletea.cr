#!/usr/bin/env bash
# Thin forwarding wrapper for the installed cross-language parity skill.
#
# Usage: check_source_parity.sh [ROOT] [MANIFEST] [SOURCE] [LANGUAGE]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/parity_skill.sh
. "${SCRIPT_DIR}/parity_skill.sh"

target="$(parity_skill_script check_source_parity.sh)"
exec "${target}" "$@"
