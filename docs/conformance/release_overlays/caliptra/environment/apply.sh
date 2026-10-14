#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 STAGED_SOURCE_ROOT OVERLAY.patch" >&2
  exit 2
fi
ROOT=$(cd "$1" && pwd)
PATCH_NAME=$2
OVERLAYS=$(cd "$(dirname "$0")" && pwd)
PATCH_FILE="$OVERLAYS/$PATCH_NAME"

case "$PATCH_NAME" in
  csrng-package-order.patch|csrng-generated-reg-include.patch) STRIP=0 ;;
  soc-ifc-assignment-patterns.patch|soc-ifc-function-return-types.patch) STRIP=0 ;;
  adams-legacy-width-alias.patch|adams-decompose-drop-stale-port.patch|adams-pkdecode-remove-stale-parameter.patch|adams-pkdecode-c339-539-address-cast.patch|adams-pkdecode-source-base.patch|adams-sigdecode-z-update-call-arity.patch|adams-skencode-drop-stale-port.patch|adams-compress-filelist-package.patch|el2-veer-remove-stale-dft-ports.patch) STRIP=1 ;;
  *) echo "unknown overlay: $PATCH_NAME" >&2; exit 2 ;;
esac
BINARY=()
[[ "$PATCH_NAME" == el2-veer-remove-stale-dft-ports.patch ]] && BINARY=(--binary)

test -f "$PATCH_FILE"
test ! -e "$ROOT/.git" || { echo "overlay root must be a staged source copy, not a Git checkout" >&2; exit 2; }
patch --batch --forward "${BINARY[@]}" --dry-run -p"$STRIP" -d "$ROOT" < "$PATCH_FILE"
patch --batch --forward "${BINARY[@]}" -p"$STRIP" -d "$ROOT" < "$PATCH_FILE"
