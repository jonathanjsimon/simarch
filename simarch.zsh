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

STAGE1=0
IS_TUXEDO=0
IS_ENDEAVOUR=0
IS_LAPTOP=0
INSTALL_PKGS=0
MIN_PKGS=0
EXTRA_PKGS=0
PIPEWIRE=0
WINE=0
STORAGEROOT="/mnt/storage/"

PLASMAVERSION=0

function binary_exists()
{
    if [ -z "${1}" ]; then
        return 1
    fi

    if (( $+commands[${1}] ))
    then
        return 0
    fi

    return 1
}

function yay_install()
{
    yes | yay "${yay_options[@]}" -S "$@"
}

function yay_remove()
{
    yes | yay "${yay_options[@]}" -Rdd "$@"
}

function install_packages()
{
    yay_options=("--useask" "--sudoloop" "--cleanmenu=false" "--diffmenu=false" "--noconfirm")
    # ${yay_options[@]}

    # let's bootstrap basics and do the rest with yay
    /usr/bin/sudo pacman -Syuu --noconfirm rustup gdb lldb yay base-devel python python-pip ipython dmidecode

    MANUFACTURER="$(sudo dmidecode -s system-manufacturer)"
    IS_VM=0

    case "${MANUFACTURER}" in
        "innotek GmbH")
            IS_VM=1
        ;;
        "TUXEDO")
            IS_TUXEDO=1
        ;;
    esac

    source /etc/os-release

    case "$ID" in
        "EndeavourOS")
            IS_ENDEAVOUR=1
        ;;
    esac

    CHASSISTYPE=$(sudo dmidecode -s chassis-type)

    case "${CHASSISTYPE}" in
        "Notebook")
            IS_LAPTOP=1
        ;;
    esac

    # configure yay?
    /usr/bin/yay --save

    rustup toolchain install stable
    rustup target add i686-unknown-linux-gnu

    if [ ${STAGE1} -eq 1 ]
    then
        echo "${boldyellow}Installing stage 1 packages${reset}"
        if binary_exists mhwd-kernel;
        then
            for f in `sudo mhwd-kernel -li | awk 'NR>2 {print $2}'`
            do
                yay_install ${f}-headers
            done
        fi

        yay_install linux-headers dkms

        yay_install emacs-nox
        yay_install bwm-ng
        yay_install eza
        yay_install caffeine-ng
        yay_install zsh
        yay_install zoxide
        yay_install python-llfuse
        yay_install borg

        yay_install neovim

        echo "${boldgreen}Changing shell to zsh${reset}"
        /usr/bin/sudo chsh -s /usr/bin/zsh ${USER}

        if [ ${IS_TUXEDO} -eq 1 ];
        then
            yay_install tuxedo-drivers-dkms
            yay_install tuxedo-control-center-bin
            if [ ${IS_LAPTOP} -eq 1 ];
            then
                yay_install tuxedo-touchpad-switch
            fi
        fi

        echo "${boldred}You should really reboot now${reset}"

        exit 0
    fi

    # get caffeine installed early
    yay_install caffeine-ng

    # octopi
    yay_install octopi
    yay_install octopi-notifier-frameworks

    # ranger + atool + supporting utilities
    yay_install ranger
    yay_install atool
    yay_install elinks
    yay_install ffmpegthumbnailer
    yay_install highlight
    yay_install libcaca
    yay_install lynx
    yay_install mediainfo
    yay_install odt2txt
    yay_install perl-image-exiftool
    yay_install poppler
    yay_install python-chardet
    yay_install ueberzug
    yay_install w3m
    yay_install bzip2
    yay_install cpio
    yay_install gzip
    yay_install lha
    yay_install xz
    yay_install lzop
    yay_install p7zip
    yay_install tar
    yay_install unace
    yay_install unrar
    yay_install zip
    yay_install unzip
    yay_install zstd

    # theme stuff
    if [ "$XDG_CURRENT_DESKTOP" = "KDE" ];
    then

        PLASMAVERSION=$(plasmashell --version | awk '{print $2}' | awk -F '.' '{print $1}')

        # fuck baloo, use plocate
        balooctl6 disable
        balooctl6 clear

        yay_install kvantum
        yay_install gtk-engine-murrine
        yay_install papirus-icon-theme
        yay_install tela-circle-icon-theme-nord-git
        yay_install nord-konsole
        yay_install nordic-wallpapers
        yay_install nordic-darker-theme
        yay_install kvantum-theme-nordic-git

        # # set the theme
        # /usr/bin/lookandfeeltool -a com.github.varlesh.materia-dark
        kvantummanager --set Nordic-Darker
        # /usr/bin/sudo wget -O /usr/share/konsole/base16-tomorrow-night.colorscheme https://raw.githubusercontent.com/cskeeters/base16-konsole/master/colorscheme/base16-tomorrow-night.colorscheme
    fi

    if [ "$XDG_CURRENT_DESKTOP" = "XFCE" ];
    then
        mkdir -p ~/.local/share/xfce4/terminal/colorschemes/
        wget -O ~/.local/share/xfce4/terminal/colorschemes/base16-tomorrow-night.16.theme https://raw.githubusercontent.com/afq984/base16-xfce4-terminal/master/colorschemes/base16-tomorrow-night.16.theme
        wget -O ~/.local/share/xfce4/terminal/colorschemes/base16-tomorrow-night.theme https://raw.githubusercontent.com/afq984/base16-xfce4-terminal/master/colorschemes/base16-tomorrow-night.theme
        xfconf-query -c xsettings -p /Net/ThemeName -s "Matcha-dark-azul"
    fi

    if [ ${MIN_PKGS} -eq 0 ]
    then
        # instead of nerd-fonts-complete
        yay_install ttf-firacode-nerd
        yay_install ttf-iosevka-nerd
        yay_install ttf-font-awesome
        yay_install otf-font-awesome
#         if [ ${EXTRA_PKGS} -eq 1 ];
#         then
#             yay_install polybar
#         fi
#         yay_install coolercontrol
        yay_install openrgb
    fi

    if [ -n "${WOL_IF}" ] && [ ${WOL} -gt 0 ]
    then
        yay_install wol-systemd

        sudo systemctl enable --now wol@${WOL_IF}.service

        sudo cat > /etc/systemd/system/wol@${WOL_IF}.timer << EOF
[Unit]
Description=Force wake on lan enabled every 60 seconds

[Timer]
OnBootSec=1min
OnUnitActiveSec=1m

[Install]
WantedBy=timers.target
EOF
        /usr/bin/sudo systemctl enable --now wol@${WOL_IF}.timer
    fi


    if [ "$XDG_CURRENT_DESKTOP" = "KDE" ];
    then
        yay_install plasma${PLASMAVERSION}-applets-thermal-monitor
        yay_install lib32-lm_sensors
        yay_install lm_sensors
        yay_install qt5-sensors

        if [ ${PLASMAVERSION} -eq 6 ];
        then
            yay_install qt6-sensors
        fi

        # replace kate with kwrite
        yay_remove kate
        yay_install kwrite

        # kgpg
        yay_install kgpg
        yay_install kwalletmanager

        if [ ${IS_ENDEAVOUR} -gt 0 ];
        then
            # kde addons
            yay_install kdeplasma-addons
        fi
    fi

    if [ ${MIN_PKGS} -eq 0 ] && [ ${PIPEWIRE} -eq 1 ] && [ ! binary_exists pipewire ];
    then
        # remove pulse, kate, etc
        echo "${boldyellow}Replacing pulseaudio with pipewire${reset}"
        yay_remove pulseaudio
        yay_remove pulseaudio-alsa
        yay_remove pulseaudio-bluetooth
        yay_remove pulseaudio-ctl
        yay_remove pulseaudio-zeroconf
        yay_remove manjaro-pulse
        yay_remove jack2

         # install pipewire
        yes | yay ${yay_options[@]} -So manjaro-pipewire wireplumber phonon-qt5-gstreamer gst-plugin-pipewire pipewire-jack easyeffects pipewire-x11-bell realtime-privileges

        # only install kde stuffs if on kde
        if [ "$XDG_CURRENT_DESKTOP" = "KDE" ];
        then
            yay_install plasma-pa
        fi
    fi

    if [ "$XDG_CURRENT_DESKTOP" = "KDE" ];
    then
	yay_install xdg-desktop-portal xdg-desktop-portal-kde
	# xdg-desktop-portal-gtk
    fi

    # btrfs tools
    if /usr/bin/sudo btrfs subvolume show / >/dev/null 2>&1 ;
    then
        echo "${boldyellow}Installing btrfs packages${reset}"

        yay_install btrfs-assistant
        yay_install btrfs-heatmap
        yay_install python-btrfs
        yay_install snapper
        yay_install bees
        yay_install btrfsmaintenance
    fi

    # some import starters, separately for risk management purposes
    yay_install fzf
    yay_install ripgrep
    yay_install gnupg
    yay_install opendoas
    yay_install emacs-nox
    yay_install gnome-keyring

    brave_pkg_name="brave-browser"
    if [ ${IS_ENDEAVOUR} -gt 0 ];
    then
        brave_pkg_name="brave-bin"
    fi

    yay_install ${brave_pkg_name} && \
        xdg-settings set default-web-browser brave.desktop && \
        xdg-mime default brave-browser.desktop x-scheme-handler/https && \
        xdg-mime default brave-browser.desktop x-scheme-handler/http

    yay_install betterbird-bin
    yay_install git
    yay_install git-lfs
    yay_install gitflow-avh
    yay_install figlet
    yay_install bc
    yay_install zsh
    yay_install htop
    yay_install btop-git
    yay_install bwm-ng
    yay_install aria2
    yay_install eza
    yay_install unzip
    yay_install mssql-tools

    yay_install debhelper
    yay_install debian-utils
    yay_install debootstrap
    yay_install devscripts

    yay_install haruna
    yay_install supersonic-desktop-bin

    yay_install scrcpy

    yay_install linux-headers dkms

    if [ $IS_VM -eq 0 ] && [ ${MIN_PKGS} -eq 0 ]
    then
        echo "${boldyellow}Installing virtualbox, must reboot to function${reset}"

        yay_install virtualbox-ext-oracle virtualbox-bin-guest-iso virtualbox-host-dkms virtualbox
        /usr/bin/sudo gpasswd -a jsimon vboxusers
    fi

    # gnome-keyring
    yay_install libgnome-keyring

    if [ ${MIN_PKGS} -eq 0 ];
    then
        # dock and ulauncher stuff
        yay_install python-pytz # soft ulauncher dependency (ulauncher extension requires it)

        yay_install ulauncher
        yay_install plasma5-applets-virtual-desktop-bar-git
        systemctl --user enable ulauncher.service
    fi

    if [ ${EXTRA_PKGS} -eq 1 ];
    then
        # docker
        yay_install docker docker-buildx docker-rootless-extras
        echo | /usr/bin/sudo tee -a /etc/subuid
        echo "$USER:231072:65536" | /usr/bin/sudo tee -a /etc/subuid

        echo | /usr/bin/sudo tee -a /etc/subgid
        echo "$USER:231072:65536" | /usr/bin/sudo tee -a /etc/subgid

        /usr/bin/sudo systemctl enable --now docker
        systemctl --user enable --now docker.socket
    fi

    if [ $IS_VM -ne 1 ] && [ ${MIN_PKGS} -eq 0 ];
    then
        # cloud stuff
        yay_install python-gpgme # unlisted Dropbox dependency
        yay_install dropbox
        if [ "$XDG_CURRENT_DESKTOP" = "KDE" ];
        then
            yay_install dolphin-plugins
        fi
        yay_install nextcloud-client

        # spotify AUR installer fails sometimes
        yay_install spotify

        # chat
        yay_install slack-desktop
        yay_install ferdium-bin
        yay_install mattermost-desktop
        # soft mattermost dependency
        yay_install trash-cli
        yay_install pnpm
        yay_install zoom

        # borg + vorta
        yay_install borg
        yay_install vorta

        # password manager
        yay_install 1password
        yay_install 1password-cli

        # protonvpn
        yay_install protonvpn

        # tailscale + ktailctl
        yay_install tailscale
        /usr/bin/sudo systemctl enable --now tailscaled

        yay_install ktailctl

        # solaar
        yay_install solaar

        # openrazer-meta
        yay_install openrazer-meta

        # polychromatic
        yay_install polychromatic

        /usr/bin/sudo gpasswd -a jsimon plugdev

        # battop
        yay_install battop

        # nvtop
        yay_install nvtop

        # powerpanel
        yay_install powerpanel
        /usr/bin/sudo systemctl enable --now pwrstatd.service

        # remote desktop
        yay_install remmina
        yay_install freerdp
    fi

    # bmap-tools
    yay_install bmap-tools

    # ventoy
    yay_install ventoy

    # pigz
    yay_install pigz

    # hdparm
    yay_install hdparm

    if [ ${IS_LAPTOP} -eq 1 ];
    then
        # touchegg
        yay_install touchegg
        yay_install touche
        /usr/bin/sudo systemctl enable touchegg
    fi

    # archive tool
    yay_install atool

    # srm
    yay_install srm

    # subversion + git
    yay_install subversion
    yay_install git

    # thefuck
    yay_install thefuck

    # code
    yay_install visual-studio-code-bin

    # zed
    yay_install zed

    # intellij
    yay_install intellij-idea-community-edition

    # scenebuilder
    yay_install javafx-scenebuilder

    if [ ${MIN_PKGS} -eq 0 ];
    then
        # gitkraken
        yay_install gitkraken

        # meld
        yay_install meld

        # postman
        yay_install postman-bin
    fi

    if [ ${MIN_PKGS} -eq 0 ];
    then
        # misc
        yay_install obsidian
        # todoist appimage sucks
        # yay_install planify
        yay_install freecad
        yay_install yt-dlp
        yay_install yt-dlp-drop-in
        yay_install smile
        yay_install inkscape
        yay_install cheese
    fi

    if [ ${EXTRA_PKGS} -eq 1 ];
    then
        yay_install ginkgocadx-bin
        yay_install deluge-gtk
        yay_install chirp-next
        yay_install hamradio-menus
        /usr/bin/sudo usermod -a -G uucp jsimon
    fi

    if [ "$XDG_CURRENT_DESKTOP" = "KDE" ];
    then
        if [ ${IS_ENDEAVOUR} -gt 0 ];
        then
            # soft dependency of discover
            yay_install packagekit-qt5

            if [ ${PLASMAVERSION} -eq 6 ];
            then
                yay_install qt6-sensors
            fi
        fi

        yay_install discover
    fi

    # misc
    yay_install baobab
    yay_install kdiskmark
    yay_install diskonaut
    yay_install diskus

    yay_install npm

    # dotnet core
    yay_install aspnet-runtime aspnet-runtime-3.1 aspnet-runtime-6.0 \
                                    aspnet-targeting-pack aspnet-targeting-pack-3.1 aspnet-targeting-pack-6.0 \
                                    dotnet-host dotnet-runtime dotnet-runtime-3.1 dotnet-runtime-6.0  \
                                    dotnet-sdk dotnet-sdk-3.1 dotnet-sdk-6.0 \
                                    dotnet-targeting-pack dotnet-targeting-pack-3.1 dotnet-targeting-pack-6.0

    # java
    yay_install jdk-openjdk jre17-openjdk jre11-openjdk jre8-openjdk \
                                    openjdk-doc openjdk17-doc openjdk11-doc openjdk8-doc \
                                    openjdk-src openjdk17-src openjdk11-src openjdk8-src

    yay_install javafx-scenebuilder

    yay_install maven

    yay_install visualvm


    if [ ${MIN_PKGS} -eq 0 ];
    then
        yay_install superpaper
    fi

    # network tools
    yay_install speedtest-cli
    yay_install speedtest++
    yay_install wireshark
    yay_install wireshark-qt

    # other utilities
    yay_install jq
    yay_install highlight
    yay_install bat
    yay_install ncdu
    yay_install shiny-mirrors
    yay_install bmap-tools
    yay_install screen
    yay_install byobu
    yay_install nmap
    yay_install vulscan
    yay_install powershell
    yay_install etherwake
    yay_install ethtool
    yay_install hexdiff
    yay_install imgcat
    yay_install immich-go
    yay_install picard
    yay_install rebuild-detector

    yay_install meson
    yay_install ninja
    yay_install gcc
    yay_install aarch64-linux-gnu-gcc
    yay_install gdb
    yay_install valgrind

    # hardware things
    yay_install i2c-tools
    yay_install nvme-cli
    yay_install smartmontools

    # install some npm stuff
    /usr/bin/sudo npm i -g html-minifier uglify-js uglifycss sass jshint

    if [ ${MIN_PKGS} -eq 0 ];
    then
        yay_install automake autoconf
        yay_install mono
        yay_install mono-msbuild
    fi

    if [ ${WINE} -eq 1 ];
    then
        yay_install wine
        yay_install lib32-gnutls
    fi

    # avahi
    yay_install avahi
    /usr/bin/sudo systemctl enable --now avahi-daemon

    # plocate
    yes | yay ${yay_options[@]} -R mlocate
    yay_install plocate
    /usr/bin/sudo updatedb
    /usr/bin/sudo systemctl enable --now plocate-updatedb.timer

    if binary_exists tailscale;
    then
        echo
        echo
        echo "${boldyellow}Must run \"sudo tailscale up --operator=${USER}\"${reset}"
    fi

    yay_install pacman-log-orphans-hook
}

function main()
{
    pushd ~

    while true; do /usr/bin/sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

    # Configure pamac and pacman now so we can install dependencies
    /usr/bin/sudo perl -p -i -e 's/^.UseSyslog/UseSyslog/g; s/^.Color/Color/g; s/^.TotalDownload/TotalDownload/g; s/^.ParallelDownloads.*/ParallelDownloads = 10/g;' /etc/pacman.conf
    /usr/bin/sudo perl -p -i -e 's/^.EnableAUR/EnableAUR/g; s/^.EnableSnap/EnableSnap/g; s/^.EnableFlatpak/EnableFlatpak/g; s/^.CheckFlatpakUpdates/CheckFlatpakUpdates/g;' /etc/pamac.conf

    if [ `grep -c 'EnableSnap' /etc/pamac.conf` -eq 0 ];
    then
        cat << EOF | /usr/bin/sudo tee -a /etc/pamac.conf
EnableSnap
EOF
    fi

    if [ `grep -c 'EnableFlatpak' /etc/pamac.conf` -eq 0 ];
    then
        cat << EOF | /usr/bin/sudo tee -a /etc/pamac.conf
EnableFlatpak
EOF
    fi

    if [ `grep -c 'CheckFlatpakUpdates' /etc/pamac.conf` -eq 0 ];
    then
        cat << EOF | /usr/bin/sudo tee -a /etc/pamac.conf
CheckFlatpakUpdates
EOF
    fi
    /usr/bin/sudo perl -p -i -e 's/^.MAKEFLAGS=.*/MAKEFLAGS="-j'$(($(nproc)/2))'"/g' /etc/makepkg.conf

    cat << 'EOF' | /usr/bin/sudo tee /etc/udev/rules.d/81-wifi-powersave.rules
# never power save wifi, the chip will disconnect from the network randomly on 5GHz

ACTION=="add", SUBSYSTEM=="net", KERNEL=="wl*", RUN+="/usr/bin/iw dev $name set power_save off"
EOF

    for dev in /sys/class/net/*; do
        [ -e "$dev"/wireless ] && /usr/bin/sudo /usr/bin/iw dev ${dev##*/} set power_save off
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
    sysctl -p /etc/sysctl.d/bbr.conf
    sysctl net.ipv4.tcp_available_congestion_control
    sysctl net.ipv4.tcp_congestion_control

# into ~/.config/1Password/settings/settings.json
# {
#   "ui.routes.lastUsedRoute": "{\"type\":\"ItemList\",\"content\":{\"unlockedRoute\":{\"collectionUuid\":\"everything\"},\"itemListType\":{\"type\":\"Vault\",\"content\":\"1A\"},\"category\":null,\"sortBehavior\":null}}",
#   "app.theme": "dark",
#   "passwordGenerator.size.characters": 25,
#   "passwordGenerator.includeSymbols": true,
#   "browsers.extension.enabled": true,
#   "keybinds.open": "CommandOrControl+Shift+\\",
#   "keybinds.autoFill": ""
# }

# into ~/.config/gtk-3.0/settings.ini and ~/.config/gtk-4.0/settings.ini
# gtk-theme-name=Materia-dark

    /usr/bin/sudo sysctl --system


    cat << 'EOF' | /usr/bin/sudo tee /etc/NetworkManager/dispatcher.d/09-timezone
#!/bin/sh
case "$2" in
    connectivity-change)
        timedatectl set-timezone "$(curl -sss --fail https://ipapi.co/timezone)"
    ;;
esac
EOF

    /usr/bin/sudo chmod +x /etc/NetworkManager/dispatcher.d/09-timezone

    if [[ ! -L ~/Dropbox ]]; then
        ln -s ${STORAGEROOT}Dropbox ~/Dropbox
    fi

    if [[ ! -L ~/Nextcloud ]]; then
        ln -s ${STORAGEROOT}Nextcloud ~/Nextcloud
    fi

    if [[ ! -L ~/MMS_Logs ]]; then
        ln -s ~/Dropbox/Autonomic/MMS_Logs ~/MMS_Logs
    fi

    if [ ${IS_ENDEAVOUR} -gt 0 ];
    then
        /usr/bin/sudo systemctl enable --now bluetooth
    fi

    if [ ${INSTALL_PKGS} -gt 0 ];
    then
        install_packages
    fi
}

for arg in "$@"
do
    case "$arg" in
        --stage1pkgs)
            INSTALL_PKGS=1
            STAGE1=1
        ;;
        --pkgs)
            INSTALL_PKGS=1
        ;;
        --minpkgs)
            INSTALL_PKGS=1
            MIN_PKGS=1
        ;;
        --extrapkgs)
            EXTRA_PKGS=1
            MIN_PKGS=0
            INSTALL_PKGS=1
        ;;
        --pipewire)
            PIPEWIRE=1
        ;;
        --wine)
            WINE=1
        ;;
        --storage=*)
            STORAGEROOT="${arg#--storage=}"
        ;;
        --wol)
            WOL=1
            WOL_IF=$(route | awk '/^default/{print $NF}')
        ;;
        --wol=*)
            WOL=1
            WOL_IF="${arg#--wol=}"
        ;;
    esac
done

main
