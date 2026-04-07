#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="${PWD}/acpi_call"
SRC_DIR="/usr/src/acpi_call-1.2.2"
DKMS_NAME="acpi_call"
DKMS_VERSION="1.2.2"
RUNNING_KERNEL="$(uname -r)"
TARGET_KERNEL="$(rpm -q --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel-devel | sort -V | tail -n1 || true)"

echo "Installing dependencies..."
sudo dnf install -y dkms kernel-devel kernel-headers git make gcc

if [[ -z "${TARGET_KERNEL:-}" ]]; then
  echo "Could not determine installed kernel-devel target." >&2
  exit 1
fi

if [[ ! -d "$REPO_DIR" ]]; then
  echo "Cloning acpi_call..."
  git clone https://github.com/mkottman/acpi_call.git "$REPO_DIR"
else
  echo "Using existing repo at $REPO_DIR"
fi

echo "Copying source into $SRC_DIR..."
sudo rm -rf "$SRC_DIR"
sudo mkdir -p "$SRC_DIR"
sudo cp -r "$REPO_DIR"/. "$SRC_DIR"

echo "Writing dkms.conf..."
sudo tee "$SRC_DIR/dkms.conf" >/dev/null <<'EOF'
PACKAGE_NAME="acpi_call"
PACKAGE_VERSION="1.2.2"
BUILT_MODULE_NAME[0]="acpi_call"
DEST_MODULE_LOCATION[0]="/extra"
AUTOINSTALL="yes"
MAKE[0]="make KERNELRELEASE=${kernelver}"
CLEAN="make clean"
EOF

echo "Resetting any previous DKMS state..."
sudo dkms remove -m "$DKMS_NAME" -v "$DKMS_VERSION" --all >/dev/null 2>&1 || true

echo "Adding DKMS module..."
sudo dkms add -m "$DKMS_NAME" -v "$DKMS_VERSION"

echo "Building DKMS module..."
sudo dkms build -m "$DKMS_NAME" -v "$DKMS_VERSION" -k "$TARGET_KERNEL"

echo "Installing DKMS module..."
sudo dkms install -m "$DKMS_NAME" -v "$DKMS_VERSION" -k "$TARGET_KERNEL"

if [[ "$RUNNING_KERNEL" != "$TARGET_KERNEL" ]]; then
  cat <<EOF

acpi_call was built for the newest installed kernel:
  target kernel:  $TARGET_KERNEL
  running kernel: $RUNNING_KERNEL

Reboot into $TARGET_KERNEL, then run:
  sudo modprobe acpi_call
  ls /proc/acpi/call

After that, test:
  echo '\_SB.WMID.SBST 0x32 0x00 0x00 0x00' | sudo tee /proc/acpi/call
  sudo cat /proc/acpi/call
  /home/nawin/Downloads/RESTAPIs/victus-fan-profile.sh status
EOF
  exit 0
fi

echo "Loading kernel module..."
sudo modprobe acpi_call

if [[ ! -e /proc/acpi/call ]]; then
  echo "acpi_call did not create /proc/acpi/call" >&2
  echo "If Secure Boot is enabled, unsigned DKMS modules may be blocked." >&2
  exit 1
fi

cat <<'EOF'

acpi_call is ready.

Candidate HP method from your DSDT:
  \_SB.WMID.SBST

Test commands:
  echo '\_SB.WMID.SBST 0x32 0x00 0x00 0x00' | sudo tee /proc/acpi/call
  sudo cat /proc/acpi/call
  /home/nawin/Downloads/RESTAPIs/victus-fan-profile.sh status

  echo '\_SB.WMID.SBST 0x63 0x00 0x00 0x00' | sudo tee /proc/acpi/call
  sudo cat /proc/acpi/call
  /home/nawin/Downloads/RESTAPIs/victus-fan-profile.sh status

  echo '\_SB.WMID.SBST 0xFF 0x00 0x00 0x00' | sudo tee /proc/acpi/call
  sudo cat /proc/acpi/call
EOF
