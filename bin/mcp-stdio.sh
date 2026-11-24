#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ -n "${LEARNING_HUB_ROOT:-}" && -d "${LEARNING_HUB_ROOT}" ]]; then
  PROJECT_ROOT="${LEARNING_HUB_ROOT}"
elif [[ -f "${PLUGIN_DIR}/.project-root" ]]; then
  PROJECT_ROOT="$(tr -d '\r\n' < "${PLUGIN_DIR}/.project-root")"
else
  PROJECT_ROOT="$(cd "${PLUGIN_DIR}/.." && pwd)"
fi

if [[ ! -d "${PROJECT_ROOT}" || ! -f "${PROJECT_ROOT}/src/mcp/stdio.ts" ]]; then
  echo "[learning-hub] Could not locate learning-hub project root at: ${PROJECT_ROOT}" >&2
  exit 1
fi

cd "${PROJECT_ROOT}"
export npm_config_update_notifier=false

ARGS=(src/mcp/stdio.ts)
if [[ -n "${LEARNING_HUB_DATA_DIR:-}" ]]; then
  ARGS+=(--data-dir "${LEARNING_HUB_DATA_DIR}")
fi

if [[ -x "${PROJECT_ROOT}/node_modules/.bin/tsx" ]]; then
  exec "${PROJECT_ROOT}/node_modules/.bin/tsx" "${ARGS[@]}"
else
  exec npx --no-install tsx "${ARGS[@]}"
fi
