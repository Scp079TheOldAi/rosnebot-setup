# Download and Install Rosnebots

```bash
git clone https://github.com/Scp079TheOldAi/rosnebot-setup.git; cd rosnebot-setup; ./install-catbots; ./update; cd .
```

Next you will have to edit the text document called accounts.txt in your rosnebot-setup folder and put the bots accounts in this format:

```
USERNAME:PASSWORD

USERNAME:PASSWORD

USERNAME:PASSWORD
```

## Required Dependencies

### Ubuntu/Debian

```bash
sudo apt-get install nodejs firejail net-tools x11-xserver-utils npm
```

### Fedora/Centos

```bash
sudo dnf install nodejs firejail net-tools xorg-x11-server-utils
```

### Arch/Manjaro/Garuda (High Support)

```bash
sudo pacman -Syu nodejs npm firejail net-tools xorg-xhost xorg-server-xvfb
```