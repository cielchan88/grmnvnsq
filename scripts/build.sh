#!/usr/bin/env bash
# Compile the watch face for Venu Sq 2. Run scripts/ciq-setup.sh once first.
#   bash scripts/build.sh            -> bin/CrimsonHud.prg (sideload to the watch)
#   bash scripts/build.sh venusq2m   -> build for Venu Sq 2 Music
set -euo pipefail
cd "$(dirname "$0")/.."

export PATH="$HOME/go/bin:$PATH"
DEVICE="${1:-venusq2}"

SDK_BIN="$(connect-iq-sdk-manager-cli sdk current-path --bin)"
export PATH="$SDK_BIN:$PATH"

if [ ! -f developer_key.der ]; then
    echo "developer_key.der not found. Run: bash scripts/ciq-setup.sh" >&2
    exit 1
fi

mkdir -p bin
monkeyc -f monkey.jungle -d "$DEVICE" -o bin/CrimsonHud.prg -y developer_key.der -w
echo
echo "Built bin/CrimsonHud.prg for $DEVICE"
