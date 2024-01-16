#!/usr/bin/env bash
# Installs NixOS Installation media for Secure Boot

# It is recommended to run this script after issuing `sudo -i` or as root.
# If it is run as a regular user it will fail in really horrible ways and you'll have to start over.

# Be sure to set the following environment variable prior to install
# or you can set them here prior to installing
#
DISK=/dev/sda

if [[ $DISK = *nvme* ]]; then
  PART_MRKR="p"
fi

echo "Double check these details:"
echo "HOSTNAME       : ${HOSTNAME}"
echo "DISK           : ${DISK}"
echo "BOOT PARTITION : ${DISK}${PART_MRKR}1"
echo "ROOT PARTITION : ${DISK}${PART_MRKR}2"

# Partition the drive with 550M boot partition and the rest btrfs
# printf "label: gpt\n,550M,U\n,,L\n" | sfdisk ${DISK}

# Format the partitions
# /boot:
mkfs.fat -F 32 ${DISK}${PART_MRKR}1

# /:
mkfs.ext4 -f ${DISK}${PART_MRKR}2


BOOT_UUID=$(ls -l /dev/disk/by-uuid | grep $(echo $DISK | sed 's/\/dev\///')1 | awk '{print $9}')
ROOT_UUID=$(ls -l /dev/disk/by-uuid | grep $(echo $DISK | sed 's/\/dev\///')2 | awk '{print $9}')

echo "${BOOT_UUID}" > .boot_uuid
echo "${ROOT_UUID}" > .root_uuid
echo "BOOT_UUID : $BOOT_UUID"
echo "ROOT_UUID : $ROOT_UUID"

# Mount partitions
# Mount /
mount "/dev/disk/by-uuid/${ROOT_UUID}" /mnt
# Create mount points
mkdir -p /mnt/boot
mount "/dev/disk/by-uuid/${BOOT_UUID}" /mnt/boot

# Generate hardware-configuration.nix
nixos-generate-config --root /mnt

# Copy configuration to /etc/nixos
cp *.nix /mnt/etc/nixos/

# Create niv project and add lanzaboote source to /mnt/etc/nixos
COMEBACK=$(pwd)
cd /mnt/etc/nixos
niv init
niv add nix-community/lanzaboote -r v0.3.0 -v 0.3.0
cd $COMEBACK

# Generate Secure Boot Keys
echo -n "Generate Secure Boot Keys? (y/N)?: "
read SEC_BOOT
SEC_BOOT=$(echo "${SEC_BOOT}" | tr '[:upper:]' '[:lower:]')

if [[ "${SEC_BOOT}" = "y" ]] || [[ "${SEC_BOOT}" = "yes" ]]; then
  sbctl create-keys -d /mnt/etc/secureboot -e /mnt/etc/secureboot/keys
else
  echo "Not Generating Secure Boot Keys!!!!!!!"
  echo "Please ensure you have secure boot keys located at /mnt/etc/secureboot before continuing or this WILL FAIL!!!"
  CONTINUE="x"
  while [ ! "${CONTINUE}" = "y"] || [{ ! "${CONTINUE}" = "yes" ]; do
    echo -n "Continue? (Y/n)"
    read CONTINUE
    CONTINUE=$(echo "${CONTINUE}" | tr '[:upper:]' '[:lower:]')
  done
fi

# Install the system
nixos-install --root /mnt
