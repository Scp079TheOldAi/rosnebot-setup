# Download and Install Rosnebots

```bash
git clone https://github.com/Scp079TheOldAi/rosnebot-setup.git; cd rosnebot-setup; chmod +x install-rosnebots update; ./install-rosnebots; ./update; cd .
```

If you see `Permission denied`, run `chmod +x install-rosnebots update` or `bash ./install-rosnebots`.

Next you will have to edit the text document called accounts.txt in your rosnebot-setup folder and put the bots accounts in this format:

```
USERNAME:PASSWORD

USERNAME:PASSWORD

USERNAME:PASSWORD
```

## Required Dependencies

`./install-rosnebots` tries to install these automatically. Manual install:

### Ubuntu/Debian/Mint/Pop!_OS

```bash
sudo apt-get install build-essential git cmake g++ nodejs npm firejail net-tools x11-xserver-utils rsync curl libsdl2-dev libglew-dev libfreetype6-dev libglvnd-dev
```

### Fedora/CentOS/RHEL

```bash
sudo dnf install cmake gcc-c++ make git nodejs npm firejail net-tools xorg-x11-server-utils rsync curl SDL2-devel glew-devel freetype-devel libglvnd-devel
```

### Arch/Manjaro/Garuda

```bash
sudo pacman -Syu base-devel cmake git nodejs npm firejail net-tools xorg-xhost xorg-server-xvfb rsync curl sdl2 glew freetype2 libglvnd
```

### openSUSE

```bash
sudo zypper install -t pattern devel_basis cmake git nodejs20 npm firejail net-tools xorg-x11-server-utils rsync curl libSDL2-devel glew-devel freetype2-devel libglvnd-devel
```

## Common errors

On failure, `./install-rosnebots` prints a **Common fixes** block (permissions, cmake, TF2, submodules, Steam paths, npm, firejail, etc.).

Typical flow after a build error:

```bash
# 1. Install TF2 in Steam and launch once
# 2. Fix submodules + libvstdlib
cd rosnehook
git submodule update --init --recursive
./scripts/copy-libvstdlib.sh
cd ..
# 3. Re-run installer
./install-rosnebots
```