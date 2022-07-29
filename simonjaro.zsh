#!/usr/bin/zsh

INSTALL_PKGS=0
MIN_PKGS=0
PIPEWIRE=0
BORG_RESTORE=0
REPO_PATH=""
PASSPHRASE=""

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

    # ranger + atool + supporting utilities
    yes | yay ${yay_options[@]} -S ranger atool-git elinks ffmpegthumbnailer highlight libcaca lynx mediainfo odt2txt perl-image-exiftool poppler python-chardet ueberzug w3m bzip2 cpio gzip lha xz lzop p7zip tar unace unrar zip unzip zstd

    # theme stuff
    if [ "$XDG_CURRENT_DESKTOP" = "KDE" ];
    then
        yes | yay ${yay_options[@]} -S kvantum materia-kde kvantum-theme-materia materia-gtk-theme gtk-engine-murrine papirus-icon-theme

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
        yes | yay ${yay_options[@]} -S nerd-fonts-complete
    else
        yes | yay ${yay_options[@]} -S nerd-fonts-fira-code
    fi

    if [ "$XDG_CURRENT_DESKTOP" = "KDE" ];
    then
        yes | yay ${yay_options[@]} -Rdd kate
        yes | yay ${yay_options[@]} -S kgpg kwrite
    fi

    if [ ${MIN_PKGS} -eq 0 ] && [ ${PIPEWIRE} -eq 1 ];
    then
        # remove pulse, kate, etc
        yes | yay ${yay_options[@]} -Rdd pulseaudio pulseaudio-alsa pulseaudio-bluetooth pulseaudio-ctl pulseaudio-zeroconf manjaro-pulse jack2
        # install pipewire
        yes | yay ${yay_options[@]} -S manjaro-pipewire wireplumber phonon-qt5-gstreamer gst-plugin-pipewire pipewire-jack easyeffects pipewire-x11-bell realtime-privileges xdg-desktop-portal-gtk

	# only install kde stuffs if on kde
	if [ "$XDG_CURRENT_DESKTOP" = "KDE" ];
	then
	    yes | yay ${yay_options[@]} -S plasma-pa xdg-desktop-portal-kde
        fi
    fi


    # some import starters
    yes | yay ${yay_options[@]} -S caffeine-ng gnupg opendoas emacs-nox gnome-keyring brave-browser git git-lfs figlet bc zsh htop bwm-ng aria2 exa unzip mssql-tools

    # virtualbox + linux kernel headers - DKMS should update after installation in next step
    if [ $IS_VM -eq 1 ];
    then
        target_kernel_headers=$(for f in `mhwd-kernel -li | awk 'NR>2 {print $2}'`; do pkgnamebase=`basename "${f%.*}"`; echo "${pkgnamebase}-headers"; done | paste -sd ' ')
        target_kernel_headers_array=("${(@s/ /)target_kernel_headers}")
        yes | yay ${yay_options[@]} -S virtualbox-guest-utils ${target_kernel_headers_array[@]}
    else
        target_kernel_headers=$(for f in `mhwd-kernel -li | awk 'NR>2 {print $2}'`; do pkgnamebase=`basename "${f%.*}"`; echo "${pkgnamebase}-headers ${pkgnamebase}-virtualbox-host-modules"; done | paste -sd ' ')
        target_kernel_headers_array=("${(@s/ /)target_kernel_headers}")
        yes | yay ${yay_options[@]} -S virtualbox virtualbox-guest-iso virtualbox-ext-oracle ${target_kernel_headers_array[@]}
    fi

    yes | yay ${yay_options[@]} -S linux-headers dkms

    # for some reason, linux414 headers get installed
    yes | yay ${yay_options[@]} -Rdd linux414-headers
    yes | yay ${yay_options[@]} -Rdd linux414-virtualbox-host-modules

    # gnome-keyring
    yes | yay ${yay_options[@]} -S libgnome-keyring

    if [ ${MIN_PKGS} -eq 0 ];
    then
        # dock and ulauncher stuff
        yes | yay ${yay_options[@]} -S latte-dock-git ulauncher plasma5-applets-virtual-desktop-bar-git
        systemctl --user enable --now ulauncher.service
    fi

    if [ $IS_VM -ne 1 ] && [ ${MIN_PKGS} -eq 0 ];
    then
        # cloud stuff
        yes | yay ${yay_options[@]} -S dropbox nextcloud-client

        # spotify AUR installer fails sometimes
        yes | yay ${yay_options[@]} -S spotify

        # chat and email
        yes | yay ${yay_options[@]} -S teams slack-desktop mailspring ferdium-bin pnpm-bin zoom

        # borg + vorta
        yes | yay ${yay_options[@]} -S borg vorta

        # password manager
        yes | yay ${yay_options[@]} -S 1password

        # protonvpn
        yes | yay ${yay_options[@]} -S protonvpn-gui
    fi

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
        yes | yay ${yay_options[@]} -S gittyup-git

        # gitahead
        yes | yay ${yay_options[@]} -S gitahead
    fi

    if [ ${MIN_PKGS} -eq 0 ];
    then
        # misc
        yes | yay ${yay_options[@]} -S obsidian todoist-appimage freecad
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
                                aspnet-runtime-3.1 aspnet-targeting-pack aspnet-targeting-pack-3.1

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
    yes | yay ${yay_options[@]} -S speedtest-cli speedtest++ protonvpn-gui

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
        if [ ${MIN_PKGS} -eq 0 ];
        then
            yes | yay ${yay_options[@]} -S mono-git mono-msbuild
        fi
    fi

    if [ ${MIN_PKGS} -eq 0 ];
    then
        # yes | yay ${yay_options[@]} -S mingw-w64-freetype2
        yes | yay ${yay_options[@]} -S wine-valve proton
    fi
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

    if [ ${BORG_RESTORE} -gt 0 ]
    then
        if ! binary_exists borg;
        then
            echo "borg must be installed"
            INSTALL_BORG=''
            while [ "${INSTALL_BORG:l}" != 'y' ] && [ "${INSTALL_BORG:l}" != 'n' ];
            do
                read "INSTALL_BORG?Install borg [y/N]? "
            done

            if [ "${INSTALL_BORG:l}" = 'y' ];
            then
                /usr/bin/sudo pamac install borg
            fi
        fi

        if binary_exists borg;
        then
            while [ -z "${REPO_PATH}" ] || ! [ -d "${REPO_PATH}" ];
            do
                read "REPO_PATH?Borg repo path? "
            done

            while [ -z "${PASSPHRASE}" ];
            do
                read "PASSPHRASE?Repo passphrase (${REPO_PATH}): "
                if [ -n "${PASSPHRASE}" ];
                then
                    export BORG_PASSPHRASE="${PASSPHRASE}"
                    borg info "${REPO_PATH}" &> /dev/null
                    if [ $? -gt 0 ] ;
                    then
                        echo "Passphrase incorrect"
                        PASSPHRASE=""
                    fi
                fi
            done
        else
            echo "borg still not installed, ignoring borg restore request"
        fi
    fi

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
fs.inotify.max_user_watchers = 1000000
EOF

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

    if [ ${INSTALL_PKGS} -gt 0 ];
    then
        install_packages
    fi

    if [ ${BORG_RESTORE} -gt 0 ];
    then
        LAST_SNAPSHOT=`borg list --short --last 1 "${REPO_PATH}"`
        echo "${LAST_SNAPSHOT}"
        borg --progress extract --strip-components 2 "${REPO_PATH}::${LAST_SNAPSHOT}" home/${USER}/{Desktop,Documents,Music,techsupport,Videos,VirtualBox\ VMs,Downloads,Development,Dropbox,.ssh,.gnupg,.gitconfig,.dotfiles,.config/BraveSoftware/Brave-Browser,.config/Ferdium,.config/superpaper,.config/obsidian,.config/deluge,.config/Mailspring,.config/Slack,.config/ulauncher,.local/share/ulauncher,.local/share/Vorta}
        # borg --progress extract --strip-components 2 "${REPO_PATH}::${LAST_SNAPSHOT}" home/${USER}/.config/obsidian
    fi
}

for arg in "$@"
do
    case "$arg" in
        --borg)
            BORG_RESTORE=1
        ;;
        --borg=*)
            BORG_RESTORE=1
            REPO_PATH="${arg#--borg=}"
        ;;
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
    esac
done

main
