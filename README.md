# NixOS 24.05 SecureBoot Installer
A utility to create a SecureBoot enabled install media

## Why?
As far as i could tell there was not a SecureBoot enabled NixOS install image.
I honestly just did it to see if it would work, and after a couple days, IT DID!!!

## Installation
### Clone this repository
```
git clone https://github.com/BeardedTek/nixos-24.05-secureboot-installer
```

### Find your USB / Disk device name
```
ls -l /dev/disk/by-id
```
Copy the device's short name
Example: `/dev/sde`

### Run the installer
You can set the target disk in a variable or enter it into the script.
```
export DISK="/dev/sde"
sudo ./install.sh
```
or
```
sudo ./install.sh
```

### Booting the Secure Boot install media
You will need to register the Secure Boot keys in your UEFI firmware.
Each manufacturer hmay have a different procesure.
Keys will be placed in the boot partition.

Once they are registered you can install NixOS as normal.
However, make sure to setup lanzaboote on your new system and copy the keys located in
`/etc/secureboot` to either your boot partition or a separate USB key to register
with your computer's UEFI firmware.
