#!/usr/bin/zsh

INSTALL_PKGS=0
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
    # some more AUR helpers for completion
    pamac install --no-confirm yay paru asp devtools python-dulwich python-fastimport python-gpgme python-paramiko bat

    # remove pulse
    /usr/bin/sudo pacman -Rdd pulseaudio pulseaudio-alsa pulseaudio-bluetooth pulseaudio-ctl pulseaudio-zeroconf
    # install pipewire
    pamac install --no-confirm manjaro-pipewire gst-plugin-pipewire plasma-pa pipewire-jack easyeffects pipewire-x11-bell realtime-privileges xdg-desktop-portal-kde

    # remove some things
    pamac remove --no-confirm kate

    # some import starters
    pamac install --no-confirm caffeine-ng gnupg kgpg kwrite 1password opendoas emacs-nox gnome-keyring brave-browser git figlet bc dkms linux-headers zsh htop bwm-ng aria2 exa unzip

    # theme stuff
    pamac install --no-confirm kvantum materia-kde kvantum-theme-materia materia-gtk-theme gtk-engine-murrine papirus-icon-theme plasma5-applets-virtual-desktop-bar-git

    # dock and ulauncher stuff
    pamac install --no-confirm latte-dock-git ulauncher ulauncher-theme-arc-dark-git

    # cloud stuff
    pamac install --no-confirm dropbox nextcloud-client

    # spotify AUR installer fails sometimes
    pamac install --no-confirm spotify

    # chat and email
    pamac install --no-confirm teams slack-desktop mailspring ferdi-bin pnpm-bin

    # archive tool
    pamac install --no-confirm atool

    # code
    pamac install --no-confirm visual-studio-code-bin gitkraken

    # VMs
    pamac install --no-confirm virtualbox virtualbox-guest-iso virtualbox-ext-oracle

    # rust
    pamac install --no-confirm rustup gdb lldb

    # misc
    pamac install --no-confirm discover baobab obsidian npm todoist-appimage

    # some more AUR helpers for completion
    pamac install --no-confirm trizen paru pacaur

    # dotnet core
    pamac install --no-confirm dotnet-host dotnet-runtime dotnet-runtime-3.1 dotnet-sdk \
                                dotnet-sdk-3.1 dotnet-targeting-pack dotnet-targeting-pack-3.1 aspnet-runtime \
                                aspnet-runtime-3.1 aspnet-targeting-pack aspnet-targeting-pack-3.1


    # installing this separately because it seems to no longer well and I wanted to be able to comment it out
    pamac install --no-confirm superpaper

    # network tools
    pamac install --no-confirm speedtest-cli speedtest++

    # other utilities
    pamac install --no-confirm jq highlight

    # get that rust
    rustup toolchain install stable
    rustup target add i686-unknown-linux-gnu

    # install some npm stuff
    sudo npm i -g html-minifier uglify-js uglifycss sass

    # mono-git build-depends on mono so we have to install it first and then replace with mono-git
    if ! binary_exists mono;
    then
        pamac install --no-confirm mono
        pamac install --no-confirm mono-git mono-msbuild
    fi

    # install some AUR things that take a while to compile
    pamac install --no-confirm wine-valve proton

    # set icons this way cuz I can
    /usr/lib/plasma-changeicons Papirus-Dark
    /usr/bin/lookandfeeltool -a com.github.varlesh.materia-dark
}

function main()
{
    pushd ~

    # Configure pamac and pacman now so we can install dependencies
    /usr/bin/sudo perl -p -i -e 's/^.UseSyslog/UseSyslog/g; s/^.Color/Color/g; s/^.TotalDownload/TotalDownload/g; s/^.ParallelDownloads.*/ParallelDownloads = 10/g;' /etc/pacman.conf
    /usr/bin/sudo perl -p -i -e 's/^.EnableAUR/EnableAUR/g; s/^.EnableSnap/EnableSnap/g; s/^.EnableFlatpak/EnableFlatpak/g; s/^.CheckFlatpakUpdates/CheckFlatpakUpdates/g;' /etc/pamac.conf
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

            if [ "${INSTALL_BORG:l}" == 'y' ];
            then
                pamac install --no-confirm borg
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

    /usr/bin/sudo sysctl --system

    /usr/bin/sudo wget -O /usr/share/konsole/base16-tomorrow-night.colorscheme https://raw.githubusercontent.com/cskeeters/base16-konsole/master/colorscheme/base16-tomorrow-night.colorscheme

    if [ ${INSTALL_PKGS} -gt 0 ];
    then
        install_packages
    fi

    if [ ${BORG_RESTORE} -gt 0 ];
    then
        LAST_SNAPSHOT=`borg list --short --last 1 "${REPO_PATH}"`
        echo "${LAST_SNAPSHOT}"
        borg --progress extract --strip-components 2 "${REPO_PATH}::${LAST_SNAPSHOT}" home/${USER}/{Desktop,Documents,Music,techsupport,Videos,VirtualBox\ VMs,Downloads,Development,Dropbox,.ssh,.gnupg,.gitconfig,/.config/BraveSoftware/Brave-Browser,.config/Ferdi,.config/superpaper,.config/obsidian}
        # borg --progress extract --strip-components 2 "${REPO_PATH}::${LAST_SNAPSHOT}" home/${USER}/.config/obsidian
    fi
}

for arg in "$@"
do
    case "$arg" in
        --borg)
            BORG_RESTORE=1
            exit 0
        ;;
        --borg=*)
            BORG_RESTORE=1
            REPO_PATH="${arg#--borg=}"
            exit 0
        ;;
        --pkgs)
            INSTALL_PKGS=1
            exit 0
        ;;
    esac
done

main