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
                yes | yay ${yay_options[@]} -S ${f}-headers
            done
        fi

        yes | yay ${yay_options[@]} -S linux-headers dkms

        yes | yay ${yay_options[@]} -S emacs-nox
        yes | yay ${yay_options[@]} -S bwm-ng
        yes | yay ${yay_options[@]} -S eza
        yes | yay ${yay_options[@]} -S caffeine-ng
        yes | yay ${yay_options[@]} -S zsh
        yes | yay ${yay_options[@]} -S zoxide
        yes | yay ${yay_options[@]} -S python-llfuse
        yes | yay ${yay_options[@]} -S borg

        yes | yay ${yay_options[@]} -S neovim

        echo "${boldgreen}Changing shell to zsh${reset}"
        /usr/bin/sudo chsh -s /usr/bin/zsh ${USER}

        if [ ${IS_TUXEDO} -eq 1 ];
        then
            yes | yay ${yay_options[@]} -S tuxedo-drivers-dkms
            yes | yay ${yay_options[@]} -S tuxedo-control-center-bin
            if [ ${IS_LAPTOP} -eq 1 ];
            then
                yes | yay ${yay_options[@]} -S tuxedo-touchpad-switch
            fi
        fi

        echo "${boldred}You should really reboot now${reset}"

        exit 0
    fi

    # get caffeine installed early
    yes | yay ${yay_options[@]} -S caffeine-ng

    # octopi
    yes | yay ${yay_options[@]} -S octopi
    yes | yay ${yay_options[@]} -S octopi-notifier-frameworks

    # ranger + atool + supporting utilities
    yes | yay ${yay_options[@]} -S ranger
    yes | yay ${yay_options[@]} -S atool
    yes | yay ${yay_options[@]} -S elinks
    yes | yay ${yay_options[@]} -S ffmpegthumbnailer
    yes | yay ${yay_options[@]} -S highlight
    yes | yay ${yay_options[@]} -S libcaca
    yes | yay ${yay_options[@]} -S lynx
    yes | yay ${yay_options[@]} -S mediainfo
    yes | yay ${yay_options[@]} -S odt2txt
    yes | yay ${yay_options[@]} -S perl-image-exiftool
    yes | yay ${yay_options[@]} -S poppler
    yes | yay ${yay_options[@]} -S python-chardet
    yes | yay ${yay_options[@]} -S ueberzug
    yes | yay ${yay_options[@]} -S w3m
    yes | yay ${yay_options[@]} -S bzip2
    yes | yay ${yay_options[@]} -S cpio
    yes | yay ${yay_options[@]} -S gzip
    yes | yay ${yay_options[@]} -S lha
    yes | yay ${yay_options[@]} -S xz
    yes | yay ${yay_options[@]} -S lzop
    yes | yay ${yay_options[@]} -S p7zip
    yes | yay ${yay_options[@]} -S tar
    yes | yay ${yay_options[@]} -S unace
    yes | yay ${yay_options[@]} -S unrar
    yes | yay ${yay_options[@]} -S zip
    yes | yay ${yay_options[@]} -S unzip
    yes | yay ${yay_options[@]} -S zstd

    # theme stuff
    if [ "$XDG_CURRENT_DESKTOP" = "KDE" ];
    then

        PLASMAVERSION=$(plasmashell --version | awk '{print $2}' | awk -F '.' '{print $1}')

        # fuck baloo, use plocate
        balooctl6 disable
        balooctl6 clear
        
        yes | yay ${yay_options[@]} -S kvantum
        yes | yay ${yay_options[@]} -S gtk-engine-murrine
        yes | yay ${yay_options[@]} -S papirus-icon-theme
        yes | yay ${yay_options[@]} -S tela-circle-icon-theme-nord-git
        yes | yay ${yay_options[@]} -S nord-konsole
        yes | yay ${yay_options[@]} -S nordic-wallpapers
        yes | yay ${yay_options[@]} -S nordic-darker-theme
        yes | yay ${yay_options[@]} -S kvantum-theme-nordic-git

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
        yes | yay ${yay_options[@]} -S ttf-firacode-nerd
        yes | yay ${yay_options[@]} -S ttf-iosevka-nerd
        yes | yay ${yay_options[@]} -S ttf-font-awesome
        yes | yay ${yay_options[@]} -S otf-font-awesome
#         if [ ${EXTRA_PKGS} -eq 1 ];
#         then
#             yes | yay ${yay_options[@]} -S polybar
#         fi
#         yes | yay ${yay_options[@]} -S coolercontrol
        yes | yay ${yay_options[@]} -S openrgb
    fi

    if [ -n "${WOL_IF}" ] && [ ${WOL} -gt 0 ]
    then
        yes | yay ${yay_options[@]} -S wol-systemd

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
        yes | yay ${yay_options[@]} -S plasma${PLASMAVERSION}-applets-thermal-monitor
        yes | yay ${yay_options[@]} -S lib32-lm_sensors
        yes | yay ${yay_options[@]} -S lm_sensors
        yes | yay ${yay_options[@]} -S qt5-sensors

        if [ ${PLASMAVERSION} -eq 6 ];
        then
            yes | yay ${yay_options[@]} -S qt6-sensors
        fi

        # replace kate with kwrite
        yes | yay ${yay_options[@]} -Rdd kate
        yes | yay ${yay_options[@]} -S kwrite

        # kgpg
        yes | yay ${yay_options[@]} -S kgpg
        yes | yay ${yay_options[@]} -S kwalletmanager

        if [ ${IS_ENDEAVOUR} -gt 0 ];
        then
            # kde addons
            yes | yay ${yay_options[@]} -S kdeplasma-addons
        fi
    fi

    if [ ${MIN_PKGS} -eq 0 ] && [ ${PIPEWIRE} -eq 1 ] && [ ! binary_exists pipewire ];
    then
        # remove pulse, kate, etc
        echo "${boldyellow}Replacing pulseaudio with pipewire${reset}"
        yes | yay ${yay_options[@]} -Rdd pulseaudio
        yes | yay ${yay_options[@]} -Rdd pulseaudio-alsa
        yes | yay ${yay_options[@]} -Rdd pulseaudio-bluetooth
        yes | yay ${yay_options[@]} -Rdd pulseaudio-ctl
        yes | yay ${yay_options[@]} -Rdd pulseaudio-zeroconf
        yes | yay ${yay_options[@]} -Rdd manjaro-pulse
        yes | yay ${yay_options[@]} -Rdd jack2

         # install pipewire
        yes | yay ${yay_options[@]} -So manjaro-pipewire wireplumber phonon-qt5-gstreamer gst-plugin-pipewire pipewire-jack easyeffects pipewire-x11-bell realtime-privileges

        # only install kde stuffs if on kde
        if [ "$XDG_CURRENT_DESKTOP" = "KDE" ];
        then
            yes | yay ${yay_options[@]} -S plasma-pa
        fi
    fi

    if [ "$XDG_CURRENT_DESKTOP" = "KDE" ];
    then
	yes | yay ${yay_options[@]} -S xdg-desktop-portal xdg-desktop-portal-kde
	# xdg-desktop-portal-gtk
    fi

    # btrfs tools
    if /usr/bin/sudo btrfs subvolume show / >/dev/null 2>&1 ;
    then
        echo "${boldyellow}Installing btrfs packages${reset}"

        yes | yay ${yay_options[@]} -S btrfs-assistant
        yes | yay ${yay_options[@]} -S btrfs-heatmap
        yes | yay ${yay_options[@]} -S python-btrfs
        yes | yay ${yay_options[@]} -S snapper
        yes | yay ${yay_options[@]} -S bees
        yes | yay ${yay_options[@]} -S btrfsmaintenance
    fi

    # some import starters, separately for risk management purposes
    yes | yay ${yay_options[@]} -S fzf
    yes | yay ${yay_options[@]} -S ripgrep
    yes | yay ${yay_options[@]} -S gnupg
    yes | yay ${yay_options[@]} -S opendoas
    yes | yay ${yay_options[@]} -S emacs-nox
    yes | yay ${yay_options[@]} -S gnome-keyring

    brave_pkg_name="brave-browser"
    if [ ${IS_ENDEAVOUR} -gt 0 ];
    then
        brave_pkg_name="brave-bin"
    fi

    yes | yay ${yay_options[@]} -S ${brave_pkg_name} && \
        xdg-settings set default-web-browser brave.desktop && \
        xdg-mime default brave-browser.desktop x-scheme-handler/https && \
        xdg-mime default brave-browser.desktop x-scheme-handler/http

    yes | yay ${yay_options[@]} -S betterbird-bin
    yes | yay ${yay_options[@]} -S git
    yes | yay ${yay_options[@]} -S git-lfs
    yes | yay ${yay_options[@]} -S gitflow-avh
    yes | yay ${yay_options[@]} -S figlet
    yes | yay ${yay_options[@]} -S bc
    yes | yay ${yay_options[@]} -S zsh
    yes | yay ${yay_options[@]} -S htop
    yes | yay ${yay_options[@]} -S btop-git
    yes | yay ${yay_options[@]} -S bwm-ng
    yes | yay ${yay_options[@]} -S aria2
    yes | yay ${yay_options[@]} -S eza
    yes | yay ${yay_options[@]} -S unzip
    yes | yay ${yay_options[@]} -S mssql-tools

    yes | yay ${yay_options[@]} -S debhelper
    yes | yay ${yay_options[@]} -S debian-utils
    yes | yay ${yay_options[@]} -S debootstrap
    yes | yay ${yay_options[@]} -S devscripts

    yes | yay ${yay_options[@]} -S haruna
    yes | yay ${yay_options[@]} -S supersonic-desktop-bin

    yes | yay ${yay_options[@]} -S scrcpy

    yes | yay ${yay_options[@]} -S linux-headers dkms

    if [ $IS_VM -eq 0 ] && [ ${MIN_PKGS} -eq 0 ]
    then
        echo "${boldyellow}Installing virtualbox, must reboot to function${reset}"

        yes | yay ${yay_options[@]} -S virtualbox-ext-oracle virtualbox-bin-guest-iso virtualbox-host-dkms virtualbox
        /usr/bin/sudo gpasswd -a jsimon vboxusers
    fi

    # gnome-keyring
    yes | yay ${yay_options[@]} -S libgnome-keyring

    if [ ${MIN_PKGS} -eq 0 ];
    then
        # dock and ulauncher stuff
        yes | yay ${yay_options[@]} -S python-pytz # soft ulauncher dependency (ulauncher extension requires it)

        yes | yay ${yay_options[@]} -S ulauncher
        yes | yay ${yay_options[@]} -S plasma5-applets-virtual-desktop-bar-git
        systemctl --user enable ulauncher.service
    fi

    if [ ${EXTRA_PKGS} -eq 1 ];
    then
        # docker
        yes | yay ${yay_options[@]} -S docker docker-buildx docker-rootless-extras
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
        yes | yay ${yay_options[@]} -S python-gpgme # unlisted Dropbox dependency
        yes | yay ${yay_options[@]} -S dropbox
        if [ "$XDG_CURRENT_DESKTOP" = "KDE" ];
        then
            yes | yay ${yay_options[@]} -S dolphin-plugins
        fi
        yes | yay ${yay_options[@]} -S nextcloud-client

        # spotify AUR installer fails sometimes
        yes | yay ${yay_options[@]} -S spotify

        # chat
        yes | yay ${yay_options[@]} -S slack-desktop
        yes | yay ${yay_options[@]} -S ferdium-bin
        yes | yay ${yay_options[@]} -S mattermost-desktop
        # soft mattermost dependency
        yes | yay ${yay_options[@]} -S trash-cli
        yes | yay ${yay_options[@]} -S pnpm
        yes | yay ${yay_options[@]} -S zoom

        # borg + vorta
        yes | yay ${yay_options[@]} -S borg
        yes | yay ${yay_options[@]} -S vorta

        # password manager
        yes | yay ${yay_options[@]} -S 1password
        yes | yay ${yay_options[@]} -S 1password-cli

        # protonvpn
        yes | yay ${yay_options[@]} -S protonvpn

        # tailscale + ktailctl
        yes | yay ${yay_options[@]} -S tailscale
        /usr/bin/sudo systemctl enable --now tailscaled

        yes | yay ${yay_options[@]} -S ktailctl

        # solaar
        yes | yay ${yay_options[@]} -S solaar

        # openrazer-meta
        yes | yay ${yay_options[@]} -S openrazer-meta

        # polychromatic
        yes | yay ${yay_options[@]} -S polychromatic

        /usr/bin/sudo gpasswd -a jsimon plugdev

        # battop
        yes | yay ${yay_options[@]} -S battop

        # nvtop
        yes | yay ${yay_options[@]} -S nvtop

        # powerpanel
        yes | yay ${yay_options[@]} -S powerpanel
        /usr/bin/sudo systemctl enable --now pwrstatd.service

        # remote desktop
        yes | yay ${yay_options[@]} -S remmina
        yes | yay ${yay_options[@]} -S freerdp
    fi

    # bmap-tools
    yes | yay ${yay_options[@]} -S bmap-tools

    # ventoy
    yes | yay ${yay_options[@]} -S ventoy

    # pigz
    yes | yay ${yay_options[@]} -S pigz

    # hdparm
    yes | yay ${yay_options[@]} -S hdparm

    if [ ${IS_LAPTOP} -eq 1 ];
    then
        # touchegg
        yes | yay ${yay_options[@]} -S touchegg
        yes | yay ${yay_options[@]} -S touche
        /usr/bin/sudo systemctl enable touchegg
    fi

    # archive tool
    yes | yay ${yay_options[@]} -S atool

    # srm
    yes | yay ${yay_options[@]} -S srm

    # subversion + git
    yes | yay ${yay_options[@]} -S subversion
    yes | yay ${yay_options[@]} -S git

    # thefuck
    yes | yay ${yay_options[@]} -S thefuck

    # code
    yes | yay ${yay_options[@]} -S visual-studio-code-bin

    # zed
    yes | yay ${yay_options[@]} -S zed

    # intellij
    yes | yay ${yay_options[@]} -S intellij-idea-community-edition-jre

    # scenebuilder
    yes | yay ${yay_options[@]} -S javafx-scenebuilder

    if [ ${MIN_PKGS} -eq 0 ];
    then
        # gitkraken
        yes | yay ${yay_options[@]} -S gitkraken

        # meld
        yes | yay ${yay_options[@]} -S meld

        # postman
        yes | yay ${yay_options[@]} -S postman-bin
    fi

    if [ ${MIN_PKGS} -eq 0 ];
    then
        # misc
        yes | yay ${yay_options[@]} -S obsidian
        # todoist appimage sucks
        # yes | yay ${yay_options[@]} -S planify
        yes | yay ${yay_options[@]} -S freecad
        yes | yay ${yay_options[@]} -S yt-dlp
        yes | yay ${yay_options[@]} -S yt-dlp-drop-in
        yes | yay ${yay_options[@]} -S smile
        yes | yay ${yay_options[@]} -S inkscape
        yes | yay ${yay_options[@]} -S cheese
    fi

    if [ ${EXTRA_PKGS} -eq 1 ];
    then
        yes | yay ${yay_options[@]} -S ginkgocadx-bin
        yes | yay ${yay_options[@]} -S deluge-gtk
        yes | yay ${yay_options[@]} -S chirp-next
        yes | yay ${yay_options[@]} -S hamradio-menus
        /usr/bin/sudo usermod -a -G uucp jsimon
    fi

    if [ "$XDG_CURRENT_DESKTOP" = "KDE" ];
    then
        if [ ${IS_ENDEAVOUR} -gt 0 ];
        then
            # soft dependency of discover
            yes | yay ${yay_options[@]} -S packagekit-qt5

            if [ ${PLASMAVERSION} -eq 6 ];
            then
                yes | yay ${yay_options[@]} -S qt6-sensors
            fi
        fi

        yes | yay ${yay_options[@]} -S discover
    fi

    # misc
    yes | yay ${yay_options[@]} -S baobab
    yes | yay ${yay_options[@]} -S kdiskmark
    yes | yay ${yay_options[@]} -S diskonaut
    yes | yay ${yay_options[@]} -S diskus

    yes | yay ${yay_options[@]} -S npm

    # dotnet core
    yes | yay ${yay_options[@]} -S aspnet-runtime aspnet-runtime-3.1 aspnet-runtime-6.0 \
                                    aspnet-targeting-pack aspnet-targeting-pack-3.1 aspnet-targeting-pack-6.0 \
                                    dotnet-host dotnet-runtime dotnet-runtime-3.1 dotnet-runtime-6.0  \
                                    dotnet-sdk dotnet-sdk-3.1 dotnet-sdk-6.0 \
                                    dotnet-targeting-pack dotnet-targeting-pack-3.1 dotnet-targeting-pack-6.0

    # java
    yes | yay ${yay_options[@]} -S jdk-openjdk jre17-openjdk jre11-openjdk jre8-openjdk \
                                    openjdk-doc openjdk17-doc openjdk11-doc openjdk8-doc \
                                    openjdk-src openjdk17-src openjdk11-src openjdk8-src

    yes | yay ${yay_options[@]} -S javafx-scenebuilder

    yes | yay ${yay_options[@]} -S maven

    yes | yay ${yay_options[@]} -S visualvm


    if [ ${MIN_PKGS} -eq 0 ];
    then
        yes | yay ${yay_options[@]} -S superpaper
    fi

    # network tools
    yes | yay ${yay_options[@]} -S speedtest-cli
    yes | yay ${yay_options[@]} -S speedtest++
    yes | yay ${yay_options[@]} -S wireshark
    yes | yay ${yay_options[@]} -S wireshark-qt

    # other utilities
    yes | yay ${yay_options[@]} -S jq
    yes | yay ${yay_options[@]} -S highlight
    yes | yay ${yay_options[@]} -S bat
    yes | yay ${yay_options[@]} -S ncdu
    yes | yay ${yay_options[@]} -S shiny-mirrors
    yes | yay ${yay_options[@]} -S bmap-tools
    yes | yay ${yay_options[@]} -S screen
    yes | yay ${yay_options[@]} -S byobu
    yes | yay ${yay_options[@]} -S nmap
    yes | yay ${yay_options[@]} -S vulscan
    yes | yay ${yay_options[@]} -S powershell
    yes | yay ${yay_options[@]} -S etherwake
    yes | yay ${yay_options[@]} -S ethtool
    yes | yay ${yay_options[@]} -S hexdiff
    yes | yay ${yay_options[@]} -S imgcat
    yes | yay ${yay_options[@]} -S immich-go
    yes | yay ${yay_options[@]} -S picard
    yes | yay ${yay_options[@]} -S rebuild-detector

    yes | yay ${yay_options[@]} -S meson
    yes | yay ${yay_options[@]} -S ninja
    yes | yay ${yay_options[@]} -S gcc
    yes | yay ${yay_options[@]} -S aarch64-linux-gnu-gcc
    yes | yay ${yay_options[@]} -S gdb
    yes | yay ${yay_options[@]} -S valgrind

    # hardware things
    yes | yay ${yay_options[@]} -S i2c-tools
    yes | yay ${yay_options[@]} -S nvme-cli
    yes | yay ${yay_options[@]} -S smartmontools

    # install some npm stuff
    /usr/bin/sudo npm i -g html-minifier uglify-js uglifycss sass jshint

    if [ ${MIN_PKGS} -eq 0 ];
    then
        yes | yay ${yay_options[@]} -S automake autoconf
        yes | yay ${yay_options[@]} -S mono
        yes | yay ${yay_options[@]} -S mono-msbuild
    fi

    if [ ${WINE} -eq 1 ];
    then
        yes | yay ${yay_options[@]} -S wine
        yes | yay ${yay_options[@]} -S lib32-gnutls
    fi

    # avahi
    yes | yay ${yay_options[@]} -S avahi
    /usr/bin/sudo systemctl enable --now avahi-daemon

    # plocate
    yes | yay ${yay_options[@]} -R mlocate
    yes | yay ${yay_options[@]} -S plocate
    /usr/bin/sudo updatedb
    /usr/bin/sudo systemctl enable --now plocate-updatedb.timer

    if binary_exists tailscale;
    then
        echo
        echo
        echo "${boldyellow}Must run \"sudo tailscale up --operator=${USER}\"${reset}"
    fi

    yes | yay ${yay_options[@]} -S pacman-log-orphans-hook
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
    /usr/bin/sudo perl -p -i -e 's/^.MAKEFLAGS=.*/MAKEFLAGS="-j8"/g' /etc/makepkg.conf

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
