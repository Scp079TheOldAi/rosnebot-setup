# Download and Install Rosnebots

```bash
git clone https://github.com/Scp079TheOldAi/rosnebot-setup.git; cd rosnebot-setup; chmod +x rosnebots update; ./rosnebots; ./update; cd .
```

If you see `Permission denied`, run `chmod +x rosnebots update` or `bash ./rosnebots`.

`install-catbots` is deprecated — use **`./rosnebots`** instead.

Next you will have to edit the text document called accounts.txt in your rosnebot-setup folder and put the bots accounts in this format:

```
USERNAME:PASSWORD

USERNAME:PASSWORD

USERNAME:PASSWORD
```

## Required Dependencies

`./rosnebots` tries to install these automatically. Manual install:

### Ubuntu/Debian

```bash
sudo apt-get install build-essential git cmake g++ nodejs npm firejail net-tools x11-xserver-utils rsync curl
```

### Fedora/Centos

```bash
sudo dnf install cmake gcc-c++ make git nodejs npm firejail net-tools xorg-x11-server-utils rsync curl
```

### Arch/Manjaro/Garuda (High Support)

```bash
sudo pacman -Syu base-devel cmake git nodejs npm firejail net-tools xorg-xhost xorg-server-xvfb rsync curl
```

## Common errors

Run `./rosnebots` again after fixing — it prints hints on failure (cmake, TF2, submodules, permissions).