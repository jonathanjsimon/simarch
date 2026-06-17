#!/usr/bin/zsh

bold=$(tput bold)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
boldred=${bold}${red}
boldgreen=${bold}${green}
boldyellow=${bold}${yellow}
boldblue=${bold}${blue}
reset=$(tput sgr0)

# ── Global state ───────────────────────────────────────────────────────────────

STAGE1=0
PROFILE="workstation"   # minimal | workstation | full
PIPEWIRE=1
WINE=0
WOL=0
WOL_IF=""
STORAGEROOT="/mnt/storage/"

# Populated by detect_environment()
IS_VM=0
IS_TUXEDO=0
IS_LAPTOP=0
IS_KDE=0
IS_XFCE=0
IS_ENDEAVOUR=0
PLASMAVERSION=0

yay_options=("--useask" "--sudoloop" "--cleanmenu=false" "--diffmenu=false" "--noconfirm")
failed_packages=()

# ── Helpers ────────────────────────────────────────────────────────────────────

function binary_exists() {
    [[ -z "${1}" ]] && return 1
    (( $+commands[${1}] )) && return 0
    return 1
}

function yay_install() {
    # Try the whole group at once — faster, resolves deps in one pass.
    # On failure, fall back to one package at a time so a single bad package
    # doesn't block the rest of the group.
    yes | yay "${yay_options[@]}" -S "$@" && return 0

    local pkg
    for pkg in "$@"; do
        yes | yay "${yay_options[@]}" -S "$pkg" || failed_packages+=("$pkg")
    done
}

function yay_remove() {
    yes | yay "${yay_options[@]}" -Rdd "$@"
}

# ── Environment detection ──────────────────────────────────────────────────────

function detect_environment() {
    local manufacturer chassistype

    manufacturer=$(sudo dmidecode -s system-manufacturer)
    case "${manufacturer}" in
        "innotek GmbH") IS_VM=1 ;;
        "TUXEDO")       IS_TUXEDO=1 ;;
    esac

    source /etc/os-release
    case "$ID" in
        "EndeavourOS") IS_ENDEAVOUR=1 ;;
    esac

    chassistype=$(sudo dmidecode -s chassis-type)
    case "${chassistype}" in
        "Notebook") IS_LAPTOP=1 ;;
    esac

    case "$XDG_CURRENT_DESKTOP" in
        "KDE")
            IS_KDE=1
            PLASMAVERSION=$(plasmashell --version | awk '{print $2}' | awk -F '.' '{print $1}')
            ;;
        "XFCE")
            IS_XFCE=1
            ;;
    esac
}

# ── Package declarations ───────────────────────────────────────────────────────
#
# Stage 1: bootstrap packages installed before the mandatory reboot.
#
# On TUXEDO hardware the drivers and control center go in stage 1 so that
# fan curves are active before the long stage 2 installation runs.  Without
# them the system may overheat mid-install.  Everything else in stage 1 is
# tooling that's useful during post-reboot config work or is a prerequisite
# for later dkms-based packages (virtualbox, etc.).

pkgs_stage1=(
    linux-headers dkms          # dkms prereq for tuxedo drivers, virtualbox, etc.
    zsh zoxide                  # shell switch takes effect after reboot
    emacs-nox neovim vim        # editors for post-reboot config
    eza bwm-ng caffeine-ng      # monitoring + prevent sleep during install
    borg python-llfuse          # backup tooling available early
)

pkgs_stage1_tuxedo=(
    tuxedo-drivers-dkms         # loads DKMS kernel modules for fan/power control
    tuxedo-control-center-bin   # fan curves — must be running before stage 2
)

pkgs_stage1_tuxedo_laptop=(tuxedo-touchpad-switch)

# ── Core (all profiles) ────────────────────────────────────────────────────────

pkgs_shell=(
    zsh zoxide eza fzf bat
    htop btop-git bwm-ng
    byobu screen thefuck
    figlet bc ripgrep
)

pkgs_compression=(
    7zip bzip2 cpio gzip lhasa xz lzop
    tar unace unrar zip unzip zstd
)

# ranger + all preview/preview-support tools it uses
pkgs_ranger=(
    ranger atool
    elinks ffmpegthumbnailer highlight libcaca lynx
    mediainfo odt2txt perl-image-exiftool poppler
    python-chardet ueberzug w3m
)

pkgs_system=(
    caffeine-ng
    octopi octopi-notifier-frameworks
    gnupg opendoas
    gnome-keyring libgnome-keyring
    avahi
    bmaptool ventoy pigz srm
    ncdu baobab diskonaut diskus
    jq bat
    shiny-mirrors rebuild-detector pacman-log-orphans-hook
)

pkgs_hardware=(
    i2c-tools-git nvme-cli smartmontools hdparm
    lm_sensors lib32-lm_sensors
    ethtool etherwake
)

pkgs_network=(
    aria2
    nmap vulscan
    speedtest-cli speedtest++
    wireshark-cli wireshark-qt
    powershell-bin
)

pkgs_fonts=(
    ttf-firacode-nerd ttf-iosevka-nerd
    otf-font-awesome
)

pkgs_git=(git git-lfs gitflow-avh subversion)

pkgs_editors=(emacs-nox neovim vim visual-studio-code-bin zed)

pkgs_build=(
    meson ninja gcc aarch64-linux-gnu-gcc gdb lldb valgrind
    automake autoconf cmake
)

pkgs_dotnet=(
    aspnet-runtime aspnet-runtime-3.1-bin aspnet-runtime-6.0
    aspnet-targeting-pack aspnet-targeting-pack-3.1-bin aspnet-targeting-pack-6.0
    dotnet-host
    dotnet-runtime dotnet-runtime-3.1-bin dotnet-runtime-6.0
    dotnet-sdk dotnet-sdk-3.1-bin dotnet-sdk-6.0
    dotnet-targeting-pack dotnet-targeting-pack-3.1-bin dotnet-targeting-pack-6.0
)

pkgs_java=(
    jdk-openjdk jdk17-openjdk jdk11-openjdk jre8-openjdk
    openjdk-doc openjdk17-doc openjdk11-doc openjdk8-doc
    openjdk-src openjdk17-src openjdk11-src openjdk8-src
    javafx-scenebuilder maven visualvm
    intellij-idea-community-edition-jre
)

pkgs_web_dev=(npm mssql-tools)

# ── Workstation profile ────────────────────────────────────────────────────────

pkgs_dev_tools=(
    gitkraken meld postman-bin
    scrcpy
    debhelper debian-utils debootstrap devscripts
)

pkgs_mono=(mono mono-msbuild)

pkgs_media=(
    haruna supersonic-desktop-bin
    yt-dlp yt-dlp-drop-in
    immich-go picard
    imgcat
    kdiskmark
)

pkgs_productivity=(
    obsidian freecad inkscape smile cheese
    superpaper
    ulauncher python-pytz
)

pkgs_security=(1password 1password-cli)

pkgs_vpn=(
    tailscale ktailctl
    proton-vpn-gtk-app proton-vpn-daemon
)

pkgs_cloud=(
    dropbox nextcloud-client
    spotify
    borg vorta
    trash-cli pnpm
)

pkgs_chat=(slack-desktop signal-desktop ferdium-bin mattermost-desktop zoom)

pkgs_remote=(remmina freerdp)

pkgs_peripherals=(
    openrazer-meta-git polychromatic
    solaar
    openrgb
    battop nvtop powerpanel
)

pkgs_virtualbox=(
    virtualbox virtualbox-host-modules-arch virtualbox-host-modules-lt
    virtualbox-guest-iso  virtualbox-ext-oracle
)

# ── Full/extra profile ─────────────────────────────────────────────────────────

pkgs_docker=(docker docker-buildx docker-rootless-extras)
pkgs_wine=(wine lib32-gnutls)
pkgs_hamradio=(chirp-next hamradio-menus)
pkgs_medical=(ginkgocadx-bin)
pkgs_extra_apps=(deluge-gtk)

# ── Conditional (desktop/hardware detected at runtime) ─────────────────────────
#
# These are assembled inside install_packages() after detect_environment() runs.

pkgs_kde_themes=(
    kvantum kvantum-theme-nordic-git
    gtk-engine-murrine
    papirus-icon-theme tela-circle-icon-theme-nord-git
    nord-konsole nordic-wallpapers nordic-darker-theme
)

# Version-specific entries (plasma${PLASMAVERSION}-applets-thermal-monitor,
# qt6-sensors, etc.) are appended inside install_packages() after detection.
pkgs_kde_extras=(
    lib32-lm_sensors qt5-sensors
    kgpg kwalletmanager
    xdg-desktop-portal xdg-desktop-portal-kde
)

pkgs_kde_endeavour=(kdeplasma-addons packagekit-qt5)

pkgs_laptop=(touchegg touche)

pkgs_btrfs=(
    btrfs-assistant btrfs-heatmap python-btrfs
    snapper bees btrfsmaintenance
)

# ── System configuration ───────────────────────────────────────────────────────

function configure_pacman() {
    /usr/bin/sudo perl -p -i -e \
        's/^.UseSyslog/UseSyslog/g;
         s/^.Color/Color/g;
         s/^.TotalDownload/TotalDownload/g;
         s/^.ParallelDownloads.*/ParallelDownloads = 10/g' \
        /etc/pacman.conf

    /usr/bin/sudo perl -p -i -e \
        's/^.EnableAUR/EnableAUR/g;
         s/^.EnableSnap/EnableSnap/g;
         s/^.EnableFlatpak/EnableFlatpak/g;
         s/^.CheckFlatpakUpdates/CheckFlatpakUpdates/g' \
        /etc/pamac.conf

    for directive in EnableSnap EnableFlatpak CheckFlatpakUpdates; do
        if ! grep -q "$directive" /etc/pamac.conf; then
            echo "$directive" | /usr/bin/sudo tee -a /etc/pamac.conf
        fi
    done

    /usr/bin/sudo perl -p -i -e \
        "s/^.MAKEFLAGS=.*/MAKEFLAGS=\"-j$(($(nproc)/2))\"/g" \
        /etc/makepkg.conf
}

function configure_system() {
    cat << 'EOF' | /usr/bin/sudo tee /etc/udev/rules.d/81-wifi-powersave.rules
# Disable wifi power save — chip disconnects randomly on 5GHz otherwise
ACTION=="add", SUBSYSTEM=="net", KERNEL=="wl*", RUN+="/usr/bin/iw dev $name set power_save off"
EOF

    for dev in /sys/class/net/*; do
        [[ -e "${dev}/wireless" ]] && /usr/bin/sudo /usr/bin/iw dev "${dev##*/}" set power_save off
    done

    cat << EOF | /usr/bin/sudo tee /etc/doas.conf
permit persist :wheel
EOF

    cat << EOF | /usr/bin/sudo tee /etc/sysctl.d/99-max-watchers.conf
fs.inotify.max_user_watches = 1000000
EOF

    cat << EOF | /usr/bin/sudo tee /etc/sysctl.d/bbr.conf
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF

    modprobe tcp_bbr
    /usr/bin/sudo sysctl --system
}

function configure_network() {
    cat << 'EOF' | /usr/bin/sudo tee /etc/NetworkManager/dispatcher.d/09-timezone
#!/bin/sh
case "$2" in
    connectivity-change)
        timedatectl set-timezone "$(curl -sss --fail https://ipapi.co/timezone)"
    ;;
esac
EOF
    /usr/bin/sudo chmod +x /etc/NetworkManager/dispatcher.d/09-timezone
}

function configure_symlinks() {
    [[ ! -L ~/Dropbox   ]] && ln -s "${STORAGEROOT}Dropbox"   ~/Dropbox
    [[ ! -L ~/Nextcloud ]] && ln -s "${STORAGEROOT}Nextcloud" ~/Nextcloud
    [[ ! -L ~/MMS_Logs  ]] && ln -s ~/Dropbox/Autonomic/MMS_Logs ~/MMS_Logs
}

function configure_kde() {
    balooctl6 disable
    balooctl6 clear
    kvantummanager --set Nordic-Darker
}

function configure_xfce() {
    local base=~/.local/share/xfce4/terminal/colorschemes
    mkdir -p "$base"
    wget -O "${base}/base16-tomorrow-night.16.theme" \
        'https://raw.githubusercontent.com/afq984/base16-xfce4-terminal/master/colorschemes/base16-tomorrow-night.16.theme'
    wget -O "${base}/base16-tomorrow-night.theme" \
        'https://raw.githubusercontent.com/afq984/base16-xfce4-terminal/master/colorschemes/base16-tomorrow-night.theme'
    xfconf-query -c xsettings -p /Net/ThemeName -s "Matcha-dark-azul"
}

# ── Stage 1 ────────────────────────────────────────────────────────────────────

function install_stage1() {
    echo "${boldyellow}Installing stage 1 bootstrap packages${reset}"

    if binary_exists mhwd-kernel; then
        for f in $(sudo mhwd-kernel -li | awk 'NR>2 {print $2}'); do
            yay_install "${f}-headers"
        done
    fi

    yay_install "${pkgs_stage1[@]}"

    if [[ $IS_TUXEDO -eq 1 ]]; then
        echo "${boldyellow}Installing TUXEDO packages for thermal management${reset}"
        yay_install "${pkgs_stage1_tuxedo[@]}"
        [[ $IS_LAPTOP -eq 1 ]] && yay_install "${pkgs_stage1_tuxedo_laptop[@]}"
    fi

    echo "${boldgreen}Changing shell to zsh${reset}"
    /usr/bin/sudo chsh -s /usr/bin/zsh "${USER}"

    echo "${boldred}Stage 1 complete — reboot now, then re-run with --pkgs or --profile=<name>${reset}"
}

# ── Stage 2 installation ───────────────────────────────────────────────────────

function install_packages() {
    # Append version- and distro-specific KDE packages now that detection has run
    if [[ $IS_KDE -eq 1 ]]; then
        pkgs_kde_extras+=("plasma${PLASMAVERSION}-applets-thermal-monitor")
        [[ $PLASMAVERSION -eq 6 ]] && pkgs_kde_extras+=(qt6-sensors)
        [[ $IS_ENDEAVOUR -eq 1 ]] && pkgs_kde_extras+=("${pkgs_kde_endeavour[@]}")
    fi

    # Build the ordered list of package groups for this profile
    local groups=(
        pkgs_shell pkgs_compression pkgs_ranger
        pkgs_system pkgs_hardware pkgs_network
        pkgs_fonts pkgs_git pkgs_editors pkgs_build
        pkgs_dotnet pkgs_java pkgs_web_dev
    )

    if [[ $PROFILE == workstation || $PROFILE == full ]]; then
        groups+=(
            pkgs_dev_tools pkgs_mono
            pkgs_media pkgs_productivity
            pkgs_security pkgs_vpn pkgs_cloud pkgs_chat
            pkgs_remote pkgs_peripherals
        )
    fi

    if [[ $PROFILE == full ]]; then
        groups+=(pkgs_docker pkgs_extra_apps pkgs_hamradio pkgs_medical)
    fi

    [[ $WINE -eq 1 ]]                             && groups+=(pkgs_wine)
    [[ $IS_KDE -eq 1 ]]                           && groups+=(pkgs_kde_themes pkgs_kde_extras)
    [[ $IS_LAPTOP -eq 1 ]]                        && groups+=(pkgs_laptop)
    [[ $IS_VM -eq 0 && $PROFILE != minimal ]]     && groups+=(pkgs_virtualbox)

    for group in $groups; do
        yay_install "${(@P)group}"
    done

    # Browser: package name differs by distro
    local brave_pkg="brave-bin"
    [[ $IS_ENDEAVOUR -eq 0 ]] && brave_pkg="brave-browser"
    yay_install "${brave_pkg}" && \
        xdg-settings set default-web-browser brave.desktop && \
        xdg-mime default brave-browser.desktop x-scheme-handler/https && \
        xdg-mime default brave-browser.desktop x-scheme-handler/http

    # KDE: swap kate for kwrite, configure KDE-specific services
    if [[ $IS_KDE -eq 1 ]]; then
        yay_remove kate
        yay_install kwrite
    fi

    # btrfs tools (auto-detected from filesystem)
    if /usr/bin/sudo btrfs subvolume show / >/dev/null 2>&1; then
        echo "${boldyellow}btrfs root detected — installing btrfs tools${reset}"
        yay_install "${pkgs_btrfs[@]}"
    fi

    # plocate replaces mlocate
    yes | yay "${yay_options[@]}" -R mlocate 2>/dev/null || true
    yay_install plocate
    /usr/bin/sudo updatedb
    /usr/bin/sudo systemctl enable --now plocate-updatedb.timer

    # Services
    /usr/bin/sudo systemctl enable --now avahi-daemon
    [[ $IS_ENDEAVOUR -eq 1 ]] && /usr/bin/sudo systemctl enable --now bluetooth

    if [[ $PROFILE != minimal ]]; then
        systemctl --user enable ulauncher.service
        /usr/bin/sudo systemctl enable --now pwrstatd.service 2>/dev/null || true
    fi

    # npm globals
    /usr/bin/sudo npm i -g html-minifier uglify-js uglifycss sass jshint

    # Group memberships (use $USER, not a hardcoded name)
    [[ $IS_VM -eq 0 && $PROFILE != minimal ]] && /usr/bin/sudo gpasswd -a "${USER}" vboxusers
    [[ $PROFILE == workstation || $PROFILE == full ]] && /usr/bin/sudo gpasswd -a "${USER}" plugdev
    [[ $PROFILE == full ]] && /usr/bin/sudo usermod -a -G uucp "${USER}"

    # Optional: PipeWire migration
    if [[ $PIPEWIRE -eq 1 ]] && ! binary_exists pipewire; then
        install_pipewire
    fi

    # Optional: WoL
    [[ $WOL -eq 1 && -n "${WOL_IF}" ]] && install_wol

    # Optional: Docker
    [[ $PROFILE == full ]] && configure_docker

    # Tailscale
    if binary_exists tailscale; then
        /usr/bin/sudo systemctl enable --now tailscaled
        echo
        echo "${boldyellow}Run: sudo tailscale up --operator=${USER}${reset}"
    fi

    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        echo
        echo "${boldred}The following packages failed to install:${reset}"
        printf '  %s\n' "${failed_packages[@]}"
    fi
}

function install_pipewire() {
    echo "${boldyellow}Replacing PulseAudio with PipeWire${reset}"
    yay_remove pulseaudio pulseaudio-alsa pulseaudio-bluetooth \
               pulseaudio-ctl pulseaudio-zeroconf manjaro-pulse jack2

    yes | yay "${yay_options[@]}" -So \
        manjaro-pipewire wireplumber phonon-qt5-gstreamer gst-plugin-pipewire \
        pipewire-jack easyeffects pipewire-x11-bell realtime-privileges

    [[ $IS_KDE -eq 1 ]] && yay_install plasma-pa
}

function install_wol() {
    [[ "$WOL_IF" =~ ^[a-zA-Z0-9_-]+$ ]] || {
        echo "${boldred}Invalid interface name: ${WOL_IF}${reset}"
        return 1
    }

    yay_install wol-systemd
    sudo systemctl enable --now "wol@${WOL_IF}.service"

    cat << EOF | /usr/bin/sudo tee /etc/systemd/system/wol@${WOL_IF}.timer
[Unit]
Description=Force wake on lan enabled every 60 seconds

[Timer]
OnBootSec=1min
OnUnitActiveSec=1m

[Install]
WantedBy=timers.target
EOF
    /usr/bin/sudo systemctl enable --now "wol@${WOL_IF}.timer"
}

function configure_docker() {
    echo | /usr/bin/sudo tee -a /etc/subuid
    echo "${USER}:231072:65536" | /usr/bin/sudo tee -a /etc/subuid
    echo | /usr/bin/sudo tee -a /etc/subgid
    echo "${USER}:231072:65536" | /usr/bin/sudo tee -a /etc/subgid
    /usr/bin/sudo systemctl enable --now docker
    systemctl --user enable --now docker.socket
}

# ── Main ───────────────────────────────────────────────────────────────────────

function main() {
    pushd ~

    trap 'kill $(jobs -p) 2>/dev/null' EXIT
    while true; do /usr/bin/sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

    /usr/bin/sudo pacman -Syuu --noconfirm rustup gdb lldb yay base-devel python python-pip ipython dmidecode
    /usr/bin/yay --save "${yay_options[@]}"
    rustup toolchain install stable
    rustup target add i686-unknown-linux-gnu

    detect_environment

    configure_pacman
    configure_system
    configure_network
    configure_symlinks

    [[ $IS_KDE -eq 1 ]]  && configure_kde
    [[ $IS_XFCE -eq 1 ]] && configure_xfce

    if [[ $STAGE1 -eq 1 ]]; then
        install_stage1
        exit 0
    fi

    install_packages
}

# ── Argument parsing ───────────────────────────────────────────────────────────

for arg in "$@"; do
    case "$arg" in
        --stage1)       STAGE1=1 ;;
        --profile=*)    PROFILE="${arg#--profile=}" ;;
        --pipewire)     PIPEWIRE=1 ;;
        --wine)         WINE=1 ;;
        --storage=*)    STORAGEROOT="${arg#--storage=}" ;;
        --wol)
            WOL=1
            WOL_IF=$(ip route show default | awk 'NR==1{print $5}')
            [[ -z "$WOL_IF" ]] && { echo "${boldred}Could not detect default interface${reset}"; exit 1; }
            ;;
        --wol=*)
            WOL=1
            WOL_IF="${arg#--wol=}"
            ;;
    esac
done

main
