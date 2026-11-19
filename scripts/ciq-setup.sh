#!/usr/bin/env bash
# One-time setup of the Connect IQ SDK + Venu Sq 2 device files on Linux
# (GitHub Codespaces, WSL, any Linux box). Run from the repo root:
#   bash scripts/ciq-setup.sh
# Your Garmin password is typed into this terminal only (hidden), passed to the
# login command once, and never written to disk by this script.
set -euo pipefail
cd "$(dirname "$0")/.."

export PATH="$HOME/go/bin:$PATH"
CIQ=connect-iq-sdk-manager-cli
CIQ_VERSION=v0.8.4
SDK_VERSION="^9.3.0"

echo "== 1/6 Java"
if ! command -v java >/dev/null 2>&1; then
    sudo apt-get update -y
    sudo apt-get install -y openjdk-17-jre-headless
fi
java -version 2>&1 | head -1

echo "== 2/6 connect-iq-sdk-manager CLI ($CIQ_VERSION, open-source, unofficial)"
if ! command -v "$CIQ" >/dev/null 2>&1; then
    if ! command -v go >/dev/null 2>&1; then
        echo "Go is not installed. Install it first: https://go.dev/doc/install" >&2
        exit 1
    fi
    go install "github.com/lindell/connect-iq-sdk-manager-cli@$CIQ_VERSION"
fi

echo "== 3/6 Garmin Connect IQ license agreement"
"$CIQ" agreement view
read -rp "Have you read and do you accept the agreement above? [y/N] " answer
case "$answer" in
    y|Y|yes|YES) "$CIQ" agreement accept ;;
    *) echo "Agreement not accepted; stopping."; exit 1 ;;
esac

echo "== 4/6 Login to your Garmin account"
echo "Two-step verification (MFA) on the account will likely make this fail."
read -rp "Garmin email: " garmin_user
read -rsp "Garmin password (hidden): " garmin_pass
echo
GARMIN_USERNAME="$garmin_user" GARMIN_PASSWORD="$garmin_pass" "$CIQ" login
unset garmin_pass

echo "== 5/6 Download SDK $SDK_VERSION and the devices listed in manifest.xml"
"$CIQ" sdk set "$SDK_VERSION"
"$CIQ" device download --manifest=manifest.xml

echo "== 6/6 Developer key"
if [ ! -f developer_key.der ]; then
    openssl genrsa -out developer_key.pem 4096
    openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key.der -nocrypt
fi

echo
echo "Setup done. Build with:  bash scripts/build.sh"
