#!/usr/bin/zsh

INSTALL_PKGS=0
MIN_PKGS=0
PIPEWIRE=0
WINE=0

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
    IS_VM=0
    if [ "$(sudo dmidecode -s system-manufacturer)" = "innotek GmbH" ];
    then
        IS_VM=1
    fi

    yay_options=("--useask" "--sudoloop" "--nocleanmenu" "--nodiffmenu" "--noconfirm")
    # ${yay_options[@]}

    # get that rust, needed for some other packages + yay + python
    /usr/bin/sudo pamac install  --no-confirm rustup gdb lldb yay base-devel python python-pip ipython
    rustup toolchain install stable
    rustup target add i686-unknown-linux-gnu


    # get caffeine installed early
    yes | yay ${yay_options[@]} -S caffeine-ng

    # ranger + atool + supporting utilities
    yes | yay ${yay_options[@]} -S ranger atool elinks ffmpegthumbnailer highlight libcaca lynx mediainfo odt2txt perl-image-exiftool poppler python-chardet ueberzug w3m bzip2 cpio gzip lha xz lzop p7zip tar unace unrar zip unzip zstd

    if [ "$XDG_CURRENT_DESKTOP" = "KDE" ];
    then
        balooctl disable
    fi

    # theme stuff
    if [ "$XDG_CURRENT_DESKTOP" = "KDE" ];
    then
        yes | yay ${yay_options[@]} -S kvantum materia-kde kvantum-theme-materia materia-gtk-theme gtk-engine-murrine papirus-icon-theme nord-konsole

        # set the theme
        /usr/bin/lookandfeeltool -a com.github.varlesh.materia-dark
        kvantummanager --set MateriaDark
        /usr/bin/sudo wget -O /usr/share/konsole/base16-tomorrow-night.colorscheme https://raw.githubusercontent.com/cskeeters/base16-konsole/master/colorscheme/base16-tomorrow-night.colorscheme
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
        yes | yay ${yay_options[@]} -S polybar
    fi

    if [ "$XDG_CURRENT_DESKTOP" = "KDE" ];
    then
        # replace kate with kwrite
        yes | yay ${yay_options[@]} -Rdd kate
        yes | yay ${yay_options[@]} -S kwrite

        # kgpg
        yes | yay ${yay_options[@]} -S kgpg
    fi

    if [ ${MIN_PKGS} -eq 0 ] && [ ${PIPEWIRE} -eq 1 ];
    then
        # remove pulse, kate, etc
        yes | yay ${yay_options[@]} -Rdd pulseaudio
        yes | yay ${yay_options[@]} -Rdd pulseaudio-alsa
        yes | yay ${yay_options[@]} -Rdd pulseaudio-bluetooth
        yes | yay ${yay_options[@]} -Rdd pulseaudio-ctl
        yes | yay ${yay_options[@]} -Rdd pulseaudio-zeroconf
        yes | yay ${yay_options[@]} -Rdd manjaro-pulse
        yes | yay ${yay_options[@]} -Rdd jack2

         # install pipewire
        yes | yay ${yay_options[@]} -S manjaro-pipewire wireplumber phonon-qt5-gstreamer gst-plugin-pipewire pipewire-jack easyeffects pipewire-x11-bell realtime-privileges xdg-desktop-portal-gtk

	# only install kde stuffs if on kde
	if [ "$XDG_CURRENT_DESKTOP" = "KDE" ];
	then
	    yes | yay ${yay_options[@]} -S plasma-pa xdg-desktop-portal-kde
        fi
    fi

    # btrfs tools
    if sudo btrfs subvolume show / >/dev/null 2>&1 ;
    then
        yes | yay ${yay_options[@]} -S btrfs-assistant btrfs-heatmap python-btrfs snapper bees btrfsmaintenance
    fi

    # some import starters, separately for risk management purposes

    yes | yay ${yay_options[@]} -S gnupg
    yes | yay ${yay_options[@]} -S opendoas
    yes | yay ${yay_options[@]} -S emacs-nox
    yes | yay ${yay_options[@]} -S gnome-keyring
    yes | yay ${yay_options[@]} -S brave-browser
    yes | yay ${yay_options[@]} -S git
    yes | yay ${yay_options[@]} -S git-lfs
    yes | yay ${yay_options[@]} -S gitflow-avh
    yes | yay ${yay_options[@]} -S figlet
    yes | yay ${yay_options[@]} -S bc
    yes | yay ${yay_options[@]} -S zsh
    yes | yay ${yay_options[@]} -S htop
    yes | yay ${yay_options[@]} -S btop
    yes | yay ${yay_options[@]} -S bwm-ng
    yes | yay ${yay_options[@]} -S aria2
    yes | yay ${yay_options[@]} -S exa
    yes | yay ${yay_options[@]} -S unzip
    yes | yay ${yay_options[@]} -S mssql-tools

    for f in `sudo mhwd-kernel -li | awk 'NR>2 {print $2}'`
    do
        yes | yay ${yay_options[@]} -S ${f}-headers ${f}-virtualbox-host-modules
    done

    yes | yay ${yay_options[@]} -S linux-headers dkms

    if [ $IS_VM -eq 0 ] && [ ${MIN_PKGS} -eq 0 ]
    then
        yes | yay ${yay_options[@]} -S virtualbox-ext-oracle virtualbox-bin-guest-iso virtualbox
    # elif [ $IS_VM -eq 1 ]
    # then

    fi
#
#    # virtualbox + linux kernel headers - DKMS should update after installation in next step
#    if [ $IS_VM -eq 1 ];
#    then
#        target_kernel_headers=$(for f in `mhwd-kernel -li | awk 'NR>2 {print $2}'`; do pkgnamebase=`basename "${f%.*}"`; echo "${pkgnamebase}-headers"; done | paste -sd ' ')
#        target_kernel_headers_array=("${(@s/ /)target_kernel_headers}")
#        yes | yay ${yay_options[@]} -S virtualbox-guest-utils ${target_kernel_headers_array[@]}
#    elif [ ${MIN_PKGS} -eq 0 ];
#    then
#        target_kernel_headers=$(for f in `mhwd-kernel -li | awk 'NR>2 {print $2}'`; do pkgnamebase=`basename "${f%.*}"`; echo "${pkgnamebase}-headers ${pkgnamebase}-virtualbox-host-modules"; done | paste -sd ' ')
#        target_kernel_headers_array=("${(@s/ /)target_kernel_headers}")
#        yes | yay ${yay_options[@]} -S virtualbox virtualbox-guest-iso virtualbox-ext-oracle ${target_kernel_headers_array[@]}
#    fi
#
#    # for some reason, linux414 headers get installed
#    yes | yay ${yay_options[@]} -Rdd linux414-headers
#    yes | yay ${yay_options[@]} -Rdd linux414-virtualbox-host-modules

    # gnome-keyring
    yes | yay ${yay_options[@]} -S libgnome-keyring

    if [ ${MIN_PKGS} -eq 0 ];
    then
        # dock and ulauncher stuff
        yes | yay ${yay_options[@]} -S ulauncher
        yes | yay ${yay_options[@]} -S plasma5-applets-virtual-desktop-bar-git
        systemctl --user enable --now ulauncher.service
    fi

    if [ $IS_VM -ne 1 ] && [ ${MIN_PKGS} -eq 0 ];
    then
        # docker
        yes | yay ${yay_options[@]} -S docker docker-buildx
        sudo systemctl enable --now docker

        # cloud stuff
        yes | yay ${yay_options[@]} -S python-gpgme # unlisted Dropbox dependency
        yes | yay ${yay_options[@]} -S dropbox
        yes | yay ${yay_options[@]} -S nextcloud-client

        # spotify AUR installer fails sometimes
        yes | yay ${yay_options[@]} -S spotify

        # chat
        yes | yay ${yay_options[@]} -S teams
        yes | yay ${yay_options[@]} -S slack-desktop
        yes | yay ${yay_options[@]} -S ferdium-nightly-bin
        yes | yay ${yay_options[@]} -S pnpm-bin
        yes | yay ${yay_options[@]} -S zoom

        # borg + vorta
        yes | yay ${yay_options[@]} -S borg vorta

        # password manager
        yes | yay ${yay_options[@]} -S 1password

        # protonvpn
        yes | yay ${yay_options[@]} -S protonvpn

        # solaar
        yes | yay ${yay_options[@]} -S solaar

        # openrazer-meta
        yes | yay ${yay_options[@]} -S openrazer-meta

        # polychromatic
        yes | yay ${yay_options[@]} -S polychromatic
    fi

    # bmap-tools
    yes | yay ${yay_options[@]} -S bmap-tools

    # pigz
    yes | yay ${yay_options[@]} -S pigz

    # hdparm
    yes | yay ${yay_options[@]} -S hdparm

    # touchegg
    yes | yay ${yay_options[@]} -S touchegg
    sudo systemctl enable --now touchegg

    # archive tool
    yes | yay ${yay_options[@]} -S atool

    # srm
    yes | yay ${yay_options[@]} -S srm

    # subversion + git
    yes | yay ${yay_options[@]} -S git subversion

    # thefuck
    yes | yay ${yay_options[@]} -S thefuck

    # code
    yes | yay ${yay_options[@]} -S visual-studio-code-bin

    if [ ${MIN_PKGS} -eq 0 ];
    then
        # gitkraken
        yes | yay ${yay_options[@]} -S gitkraken

        # gittyup
        yes | yay ${yay_options[@]} -S gittyup

        # meld
        yes | yay ${yay_options[@]} -S meld
    fi

    if [ ${MIN_PKGS} -eq 0 ];
    then
        # misc
        yes | yay ${yay_options[@]} -S obsidian-appimage
        yes | yay ${yay_options[@]} -S todoist-appimage
        yes | yay ${yay_options[@]} -S freecad
        yes | yay ${yay_options[@]} -S deluge-gtk
        yes | yay ${yay_options[@]} -S plex-desktop
        yes | yay ${yay_options[@]} -S youtube-dl
        yes | yay ${yay_options[@]} -S yt-dlp
    fi

    if [ "$XDG_CURRENT_DESKTOP" = "KDE" ];
    then
        yes | yay ${yay_options[@]} -S discover
    fi

    # misc
    yes | yay ${yay_options[@]} -S baobab npm

    # dotnet core
    yes | yay ${yay_options[@]} -S dotnet-host dotnet-runtime dotnet-runtime-3.1 dotnet-sdk \
                                dotnet-sdk-3.1 dotnet-targeting-pack dotnet-targeting-pack-3.1 aspnet-runtime \
                                aspnet-runtime-3.1 aspnet-targeting-pack aspnet-targeting-pack-3.1 \
                                dotnet-sdk-6.0 dotnet-runtime-6.0 aspnet-targeting-pack-6.0 aspnet-runtime-6.0

    # java
    yes | yay ${yay_options[@]} -S jre-openjdk jre17-openjdk jre11-openjdk jre8-openjdk \
                                    openjdk-doc openjdk17-doc openjdk11-doc openjdk8-doc \
                                    openjdk-src openjdk17-src openjdk11-src openjdk8-src


    if [ ${MIN_PKGS} -eq 0 ];
    then
        # installing this separately because it seems to no longer well and I wanted to be able to comment it out
        yes | yay ${yay_options[@]} -S superpaper
    fi

    # network tools
    yes | yay ${yay_options[@]} -S speedtest-cli speedtest++

    # other utilities
    yes | yay ${yay_options[@]} -S jq highlight bat ncdu shiny-mirrors auto-cpufreq-git bmap-tools zip ranger atool

    # install some npm stuff
    /usr/bin/sudo npm i -g html-minifier uglify-js uglifycss sass jshint

    # install some AUR things that take a while to compile

    # mono-git build-depends on mono so we have to install it first and then replace with mono-git
    if ! binary_exists mono;
    then
        yes | yay ${yay_options[@]} -S automake autoconf
        yes | yay ${yay_options[@]} -S mono
        yes | yay ${yay_options[@]} -S mono-msbuild
    fi

    if [ ${WINE} -eq 1 ];
    then
        # yes | yay ${yay_options[@]} -S mingw-w64-freetype2
        yes | yay ${yay_options[@]} -S wine-valve
        yes | yay ${yay_options[@]} -S proton
    fi

    yes | yay ${yay_options[@]} -S plocate
    sudo updatedb
}

function main()
{
    pushd ~

    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

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


    cat << EOF | /usr/bin/sudo tee /etc/NetworkManager/dispatcher.d/09-timezone
#!/bin/sh
case "$2" in
    connectivity-change)
        timedatectl set-timezone "$(curl -sss --fail https://ipapi.co/timezone)"
    ;;
esac
EOF

    if [ ${INSTALL_PKGS} -gt 0 ];
    then
        install_packages
    fi
}

for arg in "$@"
do
    case "$arg" in
        --pkgs)
            INSTALL_PKGS=1
        ;;
        --minpkgs)
            INSTALL_PKGS=1
            MIN_PKGS=1
        ;;
        --pipewire)
            PIPEWIRE=1
        ;;
        --wine)
            WINE=1
        ;;
    esac
done

main
