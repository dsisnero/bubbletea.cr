#!/usr/bin/env bash
# Thin forwarding wrapper for the installed cross-language parity skill.
#
# Usage: generate_port_inventory.sh [ROOT] [OUT] [SOURCE] [LANGUAGE] [FORCE]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/parity_skill.sh
. "${SCRIPT_DIR}/parity_skill.sh"

target="$(parity_skill_script generate_port_inventory.sh)"
exec "${target}" "$@"
