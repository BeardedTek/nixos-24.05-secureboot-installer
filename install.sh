#!/usr/bin/env bash
# Installs NixOS with btrfs

# Define Functions
check_user(){
  user=$(whoami)
  if [ "${user}" != "root" ]; then
    echo "You must either be root or run this command as sudo."
    echo ""
    echo "It is recommended to issue the command 'sudo -i' and then run this command."
    echo ""
    echo "Exiting Instlaler"
    exit 2
  fi
}

prompt(){
  # Set Variables
  question="${1} "
  default="${2}"
  double_check="${3}"
  exit_installer="${4}"
  # Build Question
  QUESTION="${question}Continue?"
  if [[ "${default}" = "n" ]]; then
    QUESTION="${QUESTION} (y/N): "
  elif [[ "${default}" = "y" ]]; then
    QUESTION="${QUESTION} (Y/n): "
  else
    QUESTION="${QUESTION} (y/n): "
  fi
  echo -n "${QUESTION}"
  read CONTINUE
  CONTINUE=$(echo "${CONTINUE}" | awk '{print tolower($0)}')
  if [[ -z "${CONTINUE}" ]]; then
    CONTINUE=$(echo "${default}" | awk '{print tolower($0)}')
  fi
  if [ "${CONTINUE}" = "n" ] || [ "${CONTINUE}" = "no" ]; then
    if [ "${exit_installer}" = "y" ]; then
      echo ""
      echo "Exiting installer.  Please try again when you're ready."
      exit 1
    fi
  elif [ "${double_check}" = "y" ]; then
    echo ""
    echo "###################################################################"
    echo "                           DOUBLE CHECK:"
    echo "###################################################################"
    echo ""
    prompt "${question}" "${default}"
  fi
  if [ "${CONTINUE}" = "y" ] || [ "${CONTINUE}" = "yes" ]; then
    CONTINUE="y"
  fi
}

get_variable(){
  question="${1}"
  default="${2}"
  echo -n "${question} (default: ${default}): "
  read answer
  if [[ -z "${answer}" ]]; then
    answer="${default}"
  fi
}

disk_info(){
  echo "###################################################################"
  echo "Double check these details:"
  echo ""
  echo "DISK           : ${DISK}"
  echo "BOOT PARTITION : ${BOOT_DISK}"
  echo "    FILESYSTEM : FAT32"
  echo ""
  echo "ROOT PARTITION : ${ROOT_DISK}"
  echo "    FILESYSTEM : EXT4"
  echo "###################################################################"
}

uuid_info(){
  echo "BOOT_UUID : $BOOT_UUID"
  echo "ROOT_UUID : $ROOT_UUID"
}

key_info(){
  created="${1}"
  if [[ "${created}" = "y" ]]; then
    echo "New SecureBoot keys generated"
    echo "Copying new keys to /mnt/boot/keys"
    cp -r /mnt/etc/secureboot/keys /mnt/boot
    copied=$?
  else
    echo "Using default SecureBoot keys."
    echo "Copying default keys to /mnt/boot/keys"
    cp -r ./keys /mnt/boot
    copied=$?
  fi

  if [[ "$copied" != "0" ]]; then
    echo "ERROR copying SecureBoot Keys!!!"
  else
    echo "Copied SecureBoot Keys successfully!"
  fi
}

get_uuid(){
  ls -l /dev/disk/by-uuid | grep $(echo $1 | sed 's/\/dev\///')${PART_MRKR}$2 | awk '{print $9}'
}

cleanup(){
  reason="$1"
  echo "Cleaning up ${reason}..."
  echo ""
  if [[ $(mount | grep $BOOT_DISK) = 0 ]]; then
    echo "Unmounting ${BOOT_DISK}..."
    umount $BOOT_DISK
    echo "Done."
    echo ""
  fi

  if [[ $(mount | grep $ROOT_DISK = 0) ]]; then
    echo "Unmounting ${ROOT_DISK}..."
    umount $ROOT_DISK
    echo "Done."
    echo ""
  fi

  echo "Cleanup complete."
}


banner(){
  echo "     ######################################################################"
  echo "     #                                                                    #"
  echo "     #      BeardedTek's NixOS SecureBoot Installer (24.05 Unstable)      #"
  echo "     # __________________________________________________________________ #"
  echo "     #                                                                    #"
  echo "     # version: 2024-01-17      GitHub: beardedtek   Youtube: @beardedtek #"
  echo "     #   https://github.com/beardedtek/nixos-24.05-secureboot-installer   #"
  echo "     # __________________________________________________________________ #"
  echo "     #                                                                    #"
  echo "     # email: kenny@beardedtek.com                  telegram: @beardedtek #"
  echo "     # discord: @beardedtek                matrix: @beardedtek:matrix.org #"
  echo "     # __________________________________________________________________ #"
  echo "     #                                                                    #"
  echo "     #               GNU Lesser Public License, version 2.1               #"
  echo "     #             https://www.gnu.org/licenses/lgpl-3.0.html             #"
  echo "     #                                                                    #"
  echo "     ######################################################################"
  echo ""
  echo ""
}


#### Start Execution
banner

check_user

# check if $DISK is set, if not, set default to '/dev/sda'
if [[ ! -z "${DISK}" ]]; then
  default_disk="${DISK}"
else
  default_disk="/dev/sda"
fi
get_variable "What disk would you like to install to?" "${default_disk}"
DISK="${answer}"

if [[ $DISK = *nvme* ]] || [[ $DISK = *loop* ]]; then
  PART_MRKR="p"
fi

# Make sure our environment is clean and disks are not mounted.
cleanup "before install"

BOOT_DISK="${DISK}${PART_MRKR}1"
ROOT_DISK="${DISK}${PART_MRKR}2"

disk_info

# Continue?
# prompt <question> <default> <double_check> <exit>
prompt "Please verify Disk Layout." "n" "y" "y"
# Partition the drive with 550M boot partition and the rest btrfs
printf "label: gpt\n,550M,U\n,,L\n" | sfdisk ${DISK}
if [[ "$?" != "0" ]]; then
  echo "Error opening ${DISK}.  Installation can not continue."
  cleanup "after failure"
  exit 3
fi

# Format the partitions
sleep 5

OG_ROOT_UUID=$(get_uuid ${DISK} 2)
OG_BOOT_UUID=$(get_uuid ${DISK} 1)

# /boot:
mkfs.fat -F 32 "${BOOT_DISK}"

if [[ "$?" != "0" ]]; then
  echo "Error making FAT32 Filesystem on ${BOOT_DISK}.  Installation can not continue."
  cleanup "after failure"
  exit 4
fi

# /:
mkfs.ext4 "$ROOT_DISK"

if [[ "$?" != "0" ]]; then
  echo "Error making ext4 Filesystem on ${BOOT_DISK}.  Installation can not continue."
  cleanup "after failure"
  exit 5
fi

ROOT_UUID=$(get_uuid ${DISK} 2)
BOOT_UUID=$(get_uuid ${DISK} 1)

if [[ "${ROOT_UUID}" = "${OG_ROOT_UUID}" ]] || [[ "${BOOT_UUID}" = "${OG_BOOT_UUID}" ]]; then
  sleep 5
  ROOT_UUID=$(get_uuid ${DISK} 2)
  BOOT_UUID=$(get_uuid ${DISK} 1)
fi

ROOT_UUID=$(ls -l /dev/disk/by-uuid | grep $(echo $DISK | sed 's/\/dev\///')${PART_MRKR}2 | awk '{print $9}')
BOOT_UUID=$(ls -l /dev/disk/by-uuid | grep $(echo $DISK | sed 's/\/dev\///')${PART_MRKR}1 | awk '{print $9}')

uuid_info

echo "Please double check that BOOT_UUID and ROOT_UUID are not empty."
echo ""
# prompt <question> <default> <double_check> <exit>
prompt "Continue?" "n" "y" "y"


# Mount partitions
# Mount /
mount "/dev/disk/by-uuid/${ROOT_UUID}" /mnt

if [[ "$?" != "0" ]]; then
  echo "Error mounting ${ROOT_UUID} at /mnt.  Installation can not continue."
  cleanup "after failure"
  exit 6
fi

# Create mount points
mkdir /mnt/boot

if [[ "$?" != "0" ]]; then
  echo "Error creating /mnt/boot mountpoint.  Installation can not continue."
  cleanup "after failure"
  exit 7
fi

mount "/dev/disk/by-uuid/${BOOT_UUID}" /mnt/boot

if [[ "$?" != "0" ]]; then
  echo "Error mounting ${BOOT_UUID} at /mnt/boot.  Installation can not continue."
  cleanup "after failure"
  exit 8
fi

# Copy configuration to /etc/nixos
echo ""
echo "Creating /mnt/etc/nixos and copying config files into it."
echo ""

mkdir -p /mnt/etc/nixos
cp -r nixos/* /mnt/etc/nixos/
sleep 10
if [[ "$?" != "0" ]]; then
  echo "Error copying configuration to /mnt/etc/nixos.  Installation can not continue."
  cleanup "after failure"
  exit 9
fi
echo "Done."
# Copy UUID information to hardware-configuration.nix
echo ""
echo "Modifying hardware-configration.nix to reference our ROOT and BOOT partition UUID's."
echo ""
sed -i -e 's/ROOT_UUID/'${ROOT_UUID}'/' /mnt/etc/nixos/hardware-configuration.nix
ROOT_UUID_REPLACE=$?

sed -i -e 's/BOOT_UUID/'${BOOT_UUID}'/' /mnt/etc/nixos/hardware-configuration.nix
BOOT_UUID_REPLACE=$?

UUID_REPLACE=$(($ROOT_UUID_REPLACE + $BOOT_UUID_REPLACE))

if [[ "$?" != "0" ]]; then
  echo "Error copying UUIDs to hardware-configuration.nix.  Installation can not continue."
  cleanup "after failure"
  exit 12
fi
echo "Done."

# Generate Secure Boot Keys?
# prompt <question> <default> <double_check> <exit>
prompt "Use Default Boot Keys?" "y" "y" "n"
SEC_BOOT="${CONTINUE}"
if [[ "${SEC_BOOT}" = "n" ]]; then
  sbctl create-keys -d /mnt/etc/secureboot -e /mnt/etc/secureboot/keys
  key_info "y"
  if [[ "$?" != "0" ]]; then
    echo "Error generating new SecureBoot keys.  Installation can not continue."
  cleanup "after failure"
    exit 10
  fi
else
  key_info "n"
fi
echo ""
echo ""
disk_info
uuid_info

# prompt <question> <default> <double_check> <exit>
prompt "Perform nixos-install --root /mnt ?" "n" "y" "y"

# Install the system
echo "Performing Installation"
echo ""

nixos-install --root /mnt
success=$?

if [ "${success}" = "0" ]; then
  echo "Install Successful!"
  echo ""
  echo "Installation Information:"
  echo ""
  disk_info
  uuid_info
  echo ""
  echo "SecureBoot keys located on boot partition.  Ensure you register them in your UEFI firmware."
  echo ""
  cleanup "after completed installation"
  echo "Your Installation disk should be ready to use!"
  echo ""
  echo "You may need to enroll the keys located on ${DISK}${PART_MRKR}1 in your UEFI Firmare"
else
  echo "Error running 'nix-install --root /mnt'.  Installation Failed."
  cleanup "after failure"
  exit 11
fi