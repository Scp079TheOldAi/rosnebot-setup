#!/usr/bin/env bash
# Shared helpers for rosnebot-setup scripts.

ROSNE_RED='\033[0;31m'
ROSNE_YELLOW='\033[1;33m'
ROSNE_GREEN='\033[0;32m'
ROSNE_BLUE='\033[0;34m'
ROSNE_RESET='\033[0m'

ROSNE_LAST_STEP=""

rosne_info()  { echo -e "${ROSNE_BLUE}[rosnebot]${ROSNE_RESET} $*"; }
rosne_warn()  { echo -e "${ROSNE_YELLOW}[warn]${ROSNE_RESET} $*"; }
rosne_ok()    { echo -e "${ROSNE_GREEN}[ok]${ROSNE_RESET} $*"; }
rosne_die()   { echo -e "${ROSNE_RED}[error]${ROSNE_RESET} $*"; print_troubleshooting; exit 1; }

rosne_set_step() {
    ROSNE_LAST_STEP="$1"
    rosne_info "$1"
}

rosne_on_err() {
    local code=$?
    echo -e "${ROSNE_RED}[error]${ROSNE_RESET} Command failed (exit $code) during: ${ROSNE_LAST_STEP:-unknown step}"
    print_troubleshooting
    exit "$code"
}

rosne_trap_errors() {
    trap 'rosne_on_err' ERR
}

print_troubleshooting() {
    cat <<'EOF'

--- Common fixes ---

  Permission denied (./rosnebots / ./update)
    chmod +x rosnebots update start stop uninstall remove-legacy indent
    # or: bash ./rosnebots

  Do not run as root
    Run as your normal user (sudo is used only when needed).

  Not a git repository / ZIP download
    git clone https://github.com/Scp079TheOldAi/rosnebot-setup.git
    cd rosnebot-setup && ./rosnebots

  sudo: a password is required / not in sudoers
    Use an account with sudo, or ask admin to add you to the sudo group.

  cmake / g++ / make not found
    Ubuntu/Debian: sudo apt install build-essential cmake git
    Fedora:        sudo dnf install gcc-c++ cmake make git
    Arch:          sudo pacman -S base-devel cmake git
    openSUSE:      sudo zypper install -t pattern devel_basis cmake git

  npm / node not found
    Ubuntu/Debian: sudo apt install nodejs npm
    Fedora:        sudo dnf install nodejs npm
    Arch:          sudo pacman -S nodejs npm

  npm EACCES / permission denied
    mkdir -p ~/.npm-global && npm config set prefix ~/.npm-global
    echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc && source ~/.bashrc

  firejail not found
    Ubuntu/Debian: sudo apt install firejail
    Fedora:        sudo dnf install firejail
    Arch:          sudo pacman -S firejail

  net-tools / route not found
    Ubuntu/Debian: sudo apt install net-tools
    Fedora:        sudo dnf install net-tools
    Arch:          sudo pacman -S net-tools

  SDL2 / GLEW / freetype cmake errors
    Ubuntu/Debian: sudo apt install libsdl2-dev libglew-dev libfreetype6-dev libglvnd-dev
    Fedora:        sudo dnf install SDL2-devel glew-devel freetype-devel libglvnd-devel
    Arch:          sudo pacman -S sdl2 glew freetype2 libglvnd

  Build failed (no bin/librosnehook.so)
    - Install Team Fortress 2 in Steam and launch it once
    - cd rosnehook && ./scripts/copy-libvstdlib.sh
    - git submodule update --init --recursive
    - Re-run: ./rosnebots

  libvstdlib.so / TF2 not found (copy-libvstdlib)
    Install TF2 via Steam. Paths checked:
      ~/.steam/steam/steamapps/common/Team Fortress 2/
      ~/.local/share/Steam/steamapps/common/Team Fortress 2/

  git clone / submodule failed
    - Check internet and GitHub access
    - git submodule sync --recursive
    - git submodule update --init --recursive
    - If shallow clone broke submodules: git clone --recursive <url>

  vacbypass-modules / IPC install failed
    rm -rf vacbypass-modules/build && ./rosnebots
    # or: cd vacbypass-modules && mkdir -p build && cd build && cmake .. && make

  Steam / TF2 path missing (nav meshes skipped)
    Install TF2 via Steam, then run ./update again.

  ./start: mount --bind failed
    Install Steam and TF2 first. Script uses:
      ~/.steam/steam/steamapps/  or  ~/.local/share/Steam/steamapps/

  Web panel port 8081 busy
    ./stop   # then ./start again

  NVIDIA TF2 crash (glshaders.cfg)
    sudo chmod 700 /opt/steamapps/common/Team\ Fortress\ 2/tf/glshaders.cfg

  Old install still uses temprosnehook/
    ./rosnebots renames it automatically, or: mv temprosnehook rosnehook

More: https://github.com/Scp079TheOldAi/rosnebot-setup/issues
EOF
}

require_not_root() {
    if [ "$(id -u)" -eq 0 ]; then
        rosne_die "Do not run this script as root. Use your normal user account."
    fi
}

require_git_repo() {
    if [ ! -d ".git" ]; then
        rosne_die "Clone the repository with git — do not use a ZIP download.
  git clone https://github.com/Scp079TheOldAi/rosnebot-setup.git"
    fi
}

ensure_script_permissions() {
    local dir="${1:-.}"
    local s
    for s in rosnebots update start stop uninstall remove-legacy indent install-catbots; do
        [ -f "$dir/$s" ] && chmod +x "$dir/$s" 2>/dev/null || true
    done
    [ -f "$dir/lib/common.sh" ] && chmod +x "$dir/lib/common.sh" 2>/dev/null || true
}

detect_os() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        case "${ID:-unknown}" in
            ubuntu|linuxmint|pop) echo ubuntu ;;
            debian) echo debian ;;
            fedora|centos|rhel|rocky|almalinux) echo fedora ;;
            arch|manjaro|garuda|endeavouros) echo arch ;;
            opensuse*|sles) echo opensuse ;;
            *) echo unknown ;;
        esac
        return
    fi
    echo unknown
}

require_cmd() {
    local cmd="$1"
    local hint="${2:-install the package that provides '$cmd'}"
    if command -v "$cmd" >/dev/null 2>&1; then
        return 0
    fi
    rosne_die "Required command '$cmd' not found. $hint"
}

install_system_deps() {
    local os
    os="$(detect_os)"
    rosne_info "Detected OS: $os (${PRETTY_NAME:-unknown})"

    case "$os" in
        ubuntu|debian)
            rosne_info "Installing packages (apt)..."
            sudo apt-get update
            sudo apt-get install -y \
                build-essential git cmake g++ gdb \
                nodejs npm firejail net-tools \
                x11-xserver-utils rsync curl dialog \
                libsdl2-dev libglew-dev libfreetype6-dev libglvnd-dev
            ;;
        fedora)
            rosne_info "Installing packages (dnf)..."
            sudo dnf install -y \
                cmake make gcc-c++ git gdb \
                nodejs npm firejail net-tools \
                xorg-x11-server-utils rsync curl dialog \
                SDL2-devel glew-devel freetype-devel libglvnd-devel
            ;;
        arch)
            rosne_info "Installing packages (pacman)..."
            sudo pacman -Syu --noconfirm --needed \
                base-devel cmake git gdb \
                nodejs npm firejail net-tools \
                xorg-xhost xorg-server-xvfb rsync curl dialog \
                sdl2 glew freetype2 libglvnd
            ;;
        opensuse)
            rosne_info "Installing packages (zypper)..."
            sudo zypper refresh
            sudo zypper install -y \
                patterns-devel-C-C++ cmake git gdb \
                nodejs20 npm firejail net-tools \
                xorg-x11-server-utils rsync curl dialog \
                libSDL2-devel glew-devel freetype2-devel libglvnd-devel
            ;;
        *)
            rosne_warn "Unknown distro — install deps manually (see README)."
            return 1
            ;;
    esac
}

cpu_count() {
    if [ -r /proc/cpuinfo ]; then
        grep -c ^processor /proc/cpuinfo
    else
        echo 2
    fi
}

steam_root() {
    local home="${HOME:-/home/$USER}"
    if [ -d "$home/.steam/steam/steamapps" ]; then
        echo "$home/.steam/steam/steamapps"
        return 0
    fi
    if [ -d "$home/.local/share/Steam/steamapps" ]; then
        echo "$home/.local/share/Steam/steamapps"
        return 0
    fi
    return 1
}

steam_tf2_dir() {
    local root
    if ! root="$(steam_root)"; then
        return 1
    fi
    if [ -d "$root/common/Team Fortress 2/tf" ]; then
        echo "$root/common/Team Fortress 2/tf"
        return 0
    fi
    return 1
}

steam_tf2_maps_dir() {
    local tf_dir
    if ! tf_dir="$(steam_tf2_dir)"; then
        return 1
    fi
    if [ -d "$tf_dir/maps" ]; then
        echo "$tf_dir/maps"
        return 0
    fi
    return 1
}

clone_or_pull() {
    local url="$1"
    local dir="$2"
    local recursive="${3:-false}"

    if [ -d "$dir/.git" ]; then
        rosne_set_step "Updating $dir"
        git -C "$dir" pull --ff-only || rosne_warn "git pull failed in $dir — continuing"
        return 0
    fi

    rosne_set_step "Cloning $dir"
    if [ "$recursive" = true ]; then
        git clone --recursive "$url" "$dir" || rosne_die "Failed to clone $url"
    else
        git clone "$url" "$dir" || rosne_die "Failed to clone $url"
    fi
}

build_rosnehook_textmode() {
    local root="${1:-.}"
    local rosne_dir="$root/rosnehook"
    local build_dir="$root/build"
    local jobs
    jobs="$(cpu_count)"

    if [ ! -d "$rosne_dir" ]; then
        rosne_die "Missing rosnehook/ — run ./rosnebots from the start."
    fi

    rosne_set_step "Initializing rosnehook submodules"
    pushd "$rosne_dir" >/dev/null || rosne_die "Cannot enter rosnehook/"
    git submodule sync --recursive 2>/dev/null || true
    git submodule update --init --recursive || rosne_die "Submodule init failed in rosnehook"
    if [ -x ./scripts/copy-libvstdlib.sh ]; then
        if ! ./scripts/copy-libvstdlib.sh; then
            rosne_warn "copy-libvstdlib.sh failed — install TF2 in Steam, then re-run ./rosnebots"
        fi
    fi
    popd >/dev/null

    rosne_set_step "Building rosnehook (cmake + make)"
    mkdir -p "$build_dir"
    pushd "$build_dir" >/dev/null || rosne_die "Cannot create build/"
    cmake -DCMAKE_BUILD_TYPE=Release \
        -DVisuals_DrawType=Textmode \
        -DVACBypass=1 \
        -DEnableWarnings=0 \
        "../rosnehook" || rosne_die "cmake failed — install SDL2/GLEW deps (see hints below)"
    make -j"$jobs" || rosne_die "make failed — TF2 libvstdlib or submodules may be missing"
    if [ ! -e "bin/librosnehook.so" ]; then
        rosne_die "Build finished but bin/librosnehook.so is missing"
    fi
    popd >/dev/null

    rosne_set_step "Installing librosnehook-textmode.so to /opt/rosnehook"
    sudo mkdir -p /opt/rosnehook/bin/ /opt/rosnehook/data/configs
    sudo cp "$build_dir/bin/librosnehook.so" /opt/rosnehook/bin/librosnehook-textmode.so
    sudo chmod -R 0755 /opt/rosnehook/data/configs/
    rosne_ok "Installed /opt/rosnehook/bin/librosnehook-textmode.so"
}

install_navmeshes() {
    local maps_dir
    if ! maps_dir="$(steam_tf2_maps_dir)"; then
        rosne_warn "TF2 maps folder not found — skipping nav mesh copy (install TF2 in Steam, then ./update)"
        return 0
    fi

    clone_or_pull "https://github.com/Scp079TheOldAi/rosnebot-database.git" "rosnebot-database" false
    pushd rosnebot-database >/dev/null
    git fetch --depth 1 2>/dev/null || true
    git reset --hard origin/master 2>/dev/null || git reset --hard origin/main 2>/dev/null || true
    popd >/dev/null

    rosne_set_step "Copying nav meshes to TF2"
    sudo rsync -a rosnebot-database/nav\ meshes/*.nav "$maps_dir/" 2>/dev/null || \
        rosne_warn "Nav mesh rsync failed — check rosnebot-database/nav meshes/"
    sudo chmod 755 "$maps_dir"/*.nav 2>/dev/null || true
    rosne_ok "Nav meshes updated"
}