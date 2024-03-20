# My NixOS configuration files
Desclaimer: All of the configurations files assume the user is named `pavel`.

## Installation guide

### 1. Installing NixOS and Home Manager
Download the [NixOS ISO](https://nixos.org/download/) and install it.

Install Home Manager by adding its channel and switch Nix to the unstable channel:
```bash
sudo nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
sudo nix-channel --add https://channels.nixos.org/nixos-unstable nixos
sudo nix-channel --update
```

### 2. Linking this configuration
First, we must temporarily install git:
```bash
nix-shell -p git
```
In this temporary shell call:
```bash
git clone git@github.com:gyromean/qmk-config.git ~/.config/nixos-config
```

Now we need to properly link the repo files:

Firstly, remove the current configuration and link this one:
```bash
sudo rm /etc/nixos/configuration.nix
sudo ln -s /home/pavel/.config/nixos-config/common/nix-files/configuration.nix /etc/nixos/configuration.nix
```
Secondly, we need to link the machine specific settings. In the following commmand, replace the `<device>` with `desktop` or `laptop`, depending on which device you are using:
```bash
sudo -ln -s /home/pavel/.config/nixos-config/<device> /etc/nixos/machine
```

### 3. Building the system
To build the system, call:
```bash
sudo nixos-rebuild switch --upgrade
```
Finally, restart the system.

## Optional steps

### Setting up ssh keys

Call:
```bash
ssh-keygen
```
The newly generated keys are stored in `~/.ssh`. The public key (`id_rsa.pub`) can now be uploaded to github or gitlab.

## Rebuilding system
The two primary commands:
```bash
sudo nixos-rebuild switch # adds the new generation to grub, meaning next time you boot the changes are used (many of the changes take affect immediately, but not all)
sudo nixos-rebuild test # does not add the new generation to grub, meaning after rebooting the effects of this command no longer exist
```

## Updating packages
Update channels:
```bash
sudo nix-channel --update
```
After that, rebuild system as described in the previous section.

## Upgrading system
Switch to new NixOS and Home Manager channels. In this guide we use the unstable channel which is always the newest, so we do not have to worry about this step.

Then rebuild system with the `--upgrade` flag, i.e.:
```bash
sudo nixos-rebuild switch --upgrade
```

## Freeing up space

### Delete old generations
This deletes all unused packages and all generations (except the newest):
```bash
sudo nix-collect-garbage -d
```

### Deduplicating packages
Tries to hardlink identical packages:
```bash
sudo nix-store --optimise
```
