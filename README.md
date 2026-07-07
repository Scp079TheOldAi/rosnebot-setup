<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:1a1a2e,50:16213e,100:0f3460&height=200&section=header&text=Rosnebot%20Setup&fontSize=60&fontColor=e94560&animation=twinkling" alt="Rosnebot Setup"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-Linux-1793d1?style=for-the-badge&logo=linux&logoColor=white" alt="Linux"/>
  <img src="https://img.shields.io/badge/TF2-Team%20Fortress%202-f5a623?style=for-the-badge" alt="TF2"/>
  <img src="https://img.shields.io/badge/bot%20farm-setup-0f3460?style=for-the-badge" alt="Bot farm"/>
</p>

---

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

---

## Required Dependencies

**Ubuntu/Debian**

```bash
sudo apt-get install nodejs firejail net-tools x11-xserver-utils npm
```

**Fedora/Centos**

```bash
sudo dnf install nodejs firejail net-tools xorg-x11-server-utils
```

**Arch/Manjaro/Garuda (High Support)**

```bash
sudo pacman -Syu nodejs npm firejail net-tools xorg-xhost xorg-server-xvfb
```