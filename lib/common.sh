#!/usr/bin/env bash
# Shared helpers for rosnebot-setup scripts.

ROSNE_RED='\033[0;31m'
ROSNE_YELLOW='\033[1;33m'
ROSNE_GREEN='\033[0;32m'
ROSNE_BLUE='\033[0;34m'
ROSNE_RESET='\033[0m'

rosne_info()  { echo -e "${ROSNE_BLUE}[rosnebot]${ROSNE_RESET} $*"; }
rosne_warn()  { echo -e "${ROSNE_YELLOW}[warn]${ROSNE_RESET} $*"; }
rosne_ok()    { echo -e "${ROSNE_GREEN}[ok]${ROSNE_RESET} $*"; }
rosne_die()   { echo -e "${ROSNE_RED}[error]${ROSNE_RESET} $*"; print_troubleshooting; exit 1; }

print_troubleshooting() {
    cat <<'EOF'

--- Common fixes ---

  Permission denied (./rosnebots / ./update)
    chmod +x rosnebots update start stop uninstall remove-legacy indent
    # or: bash ./rosnebots

  Do not run as root
    Run as your normal user (sudo is used only when needed).

  cmake / g++ / make not found
    Ubuntu/Debian: sudo apt install build-essential cmake git
    Fedora:        sudo dnf install gcc-c++ cmake make git
    Arch:          sudo pacman -S base-devel cmake git

  npm / node not found
    Ubuntu/Debian: sudo apt install nodejs npm
    Fedora:        sudo dnf install nodejs npm
    Arch:          sudo pacman -S nodejs npm

  firejail not found
    Ubuntu/Debian: sudo apt install firejail
    Fedora:        sudo dnf install firejail
    Arch:          sudo pacman -S firejail

  net-tools / route not found
    Ubuntu/Debian: sudo apt install net-tools
    Fedora:        sudo dnf install net-tools
    Arch:          sudo pacman -S net-tools

  Build failed (no bin/librosnehook.so)
    - Install Team Fortress 2 in Steam first
    - cd rosnehook && ./scripts/copy-libvstdlib.sh
    - git submodule update --init --recursive
    - Re-run: ./rosnebots

  git clone / submodule failed
    - Check internet and GitHub access
    - git submodule sync --recursive
    - git submodule update --init --recursive

  Steam / TF2 path missing (nav meshes skipped)
    Install TF2 via Steam, then run ./update again.

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
}

detect_os() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        case "${ID:-unknown}" in
            ubuntu) echo ubuntu ;;
            debian) echo debian ;;
            fedora|centos|rhel) echo fedora ;;
            arch|manjaro|garuda) echo arch ;;
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
    rosne_info "Detected OS: $os"

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

steam_tf2_maps_dir() {
    local home="${HOME:-/home/$USER}"
    if [ -d "$home/.steam/steam/steamapps/common/Team Fortress 2/tf/maps" ]; then
        echo "$home/.steam/steam/steamapps/common/Team Fortress 2/tf/maps"
        return 0
    fi
    if [ -d "$home/.local/share/Steam/steamapps/common/Team Fortress 2/tf/maps" ]; then
        echo "$home/.local/share/Steam/steamapps/common/Team Fortress 2/tf/maps"
        return 0
    fi
    return 1
}

clone_or_pull() {
    local url="$1"
    local dir="$2"
    local recursive="${3:-false}"

    if [ -d "$dir/.git" ]; then
        rosne_info "Updating $dir..."
        git -C "$dir" pull --ff-only || rosne_warn "git pull failed in $dir — continuing"
        return 0
    fi

    rosne_info "Cloning $dir..."
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

    pushd "$rosne_dir" >/dev/null || rosne_die "Cannot enter rosnehook/"
    git submodule update --init --recursive || rosne_die "Submodule init failed in rosnehook"
    if [ -x ./scripts/copy-libvstdlib.sh ]; then
        ./scripts/copy-libvstdlib.sh || rosne_warn "copy-libvstdlib.sh skipped (TF2 may not be installed yet)"
    fi
    popd >/dev/null

    mkdir -p "$build_dir"
    pushd "$build_dir" >/dev/null || rosne_die "Cannot create build/"
    cmake -DCMAKE_BUILD_TYPE=Release \
        -DVisuals_DrawType=Textmode \
        -DVACBypass=1 \
        -DEnableWarnings=0 \
        "../rosnehook" || rosne_die "cmake failed — see errors above"
    make -j"$jobs" || rosne_die "make failed — TF2 libvstdlib or submodules may be missing"
    if [ ! -e "bin/librosnehook.so" ]; then
        rosne_die "Build finished but bin/librosnehook.so is missing"
    fi
    popd >/dev/null

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

    rosne_info "Copying nav meshes to TF2..."
    sudo rsync -a rosnebot-database/nav\ meshes/*.nav "$maps_dir/" 2>/dev/null || \
        rosne_warn "Nav mesh rsync failed — check rosnebot-database/nav meshes/"
    sudo chmod 755 "$maps_dir"/*.nav 2>/dev/null || true
    rosne_ok "Nav meshes updated"
}