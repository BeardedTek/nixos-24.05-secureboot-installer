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
[install.webm](https://github.com/BeardedTek/nixos-24.05-secureboot-installer/assets/93575915/69777484-1288-4b81-b33e-b602e057b906)

### Booting the Secure Boot install media

This is the sticking point for now.  In order to use lanzaboote, you must delete all secureboot keys which puts your firmware in setup mode.

Follow the instructions from [Foxboron/sbctl on GitHub](https://github.com/Foxboron/sbctl/blob/master/docs/workflow-example.md).

install.sh does everything pre key registration.  Once you reset your secureboot to setup mode, follow the instructions from [nix-community/lanzaboote on GitHub](https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md#part-2-enabling-secure-boot).

### Setting up your new NixOS install
I'm working on these instructions now.  I have some good ideas, and I got mine working, but I'm actually not sure how and why yet.  I'm looking all that over now to figure out exactly what I did right :P

