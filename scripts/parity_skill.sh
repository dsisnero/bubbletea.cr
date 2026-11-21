#!/usr/bin/env bash
# Resolve the installed cross-language parity skill.
#
# This repository keeps no copy of the parity implementation: every script here
# forwards to the canonical scripts in the installed skill. Set PARITY_SKILL_DIR
# when the skill lives somewhere other than the default location below.

PARITY_SKILL_DIR="${PARITY_SKILL_DIR:-${HOME}/.agents/skills/crystal_forge/skills/cross-language-crystal-parity}"

# The per-symbol ledgers use `regex` discovery vocabulary. Keep that policy
# until a reviewed manifest + ID migration changes it (see CLAUDE.md).
PORT_PARSER="${PORT_PARSER:-regex}"
export PARITY_SKILL_DIR PORT_PARSER

# Print the absolute path of a canonical skill script, or fail loudly. Callers
# use this inside a command substitution, so an exit here aborts the wrapper.
parity_skill_script() {
  local name="${1:?skill script name required}"
  local path="${PARITY_SKILL_DIR}/scripts/${name}"

  if [[ ! -x "${path}" ]]; then
    echo "[parity] canonical skill script missing: ${path}" >&2
    echo "[parity] install the cross-language-crystal-parity skill or set PARITY_SKILL_DIR" >&2
    exit 2
  fi

  printf '%s\n' "${path}"
}
