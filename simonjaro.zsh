#!/usr/bin/zsh

pushd ~

INSTALL_PKGS=0
REPO_PATH="${1}"

if [ -z "${REPO_PATH}" ] || ! [ -d "${REPO_PATH}" ];
then
    echo "Invalid repo path"
    exit 1
fi

PASSPHRASE=''
read "PASSPHRASE?Repo passphrase (${REPO_PATH}): "

if [ -z "${PASSPHRASE}" ];
then
    echo "Must supply repo passphrase"
    exit 2
fi

export BORG_PASSPHRASE="${PASSPHRASE}"
borg info "${REPO_PATH}" &> /dev/null
if [ $? -gt 0 ] ;
then
    echo "Passhrase incorrect"
    exit 3
fi

cat << EOF | /usr/bin/sudo tee /etc/udev/rules.d/81-wifi-powersave.rules
# never power save wifi, the chip will disconnect from the network randomly on 5GHz

ACTION=="add", SUBSYSTEM=="net", KERNEL=="wl*", RUN+="/usr/bin/iw dev $name set power_save off"
EOF

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
    /usr/bin/sudo perl -p -i -e 's/^.UseSyslog/UseSyslog/g; s/^.Color/Color/g; s/^.TotalDownload/TotalDownload/g; s/^.ParallelDownloads.*/ParallelDownloads = 10/g' /etc/pacman.conf
    /usr/bin/sudo perl -p -i -e 's/^.MAKEFLAGS=.*/MAKEFLAGS="-j8"/g' /etc/makepkg.conf
    # remove some things
    pamac remove kate

    # install a bunch
    pamac install --no-confirm yay opendoas emacs-nox visual-studio-code-bin \
                                gnome-keyring brave-browser git dkms linux-headers \
                                figlet git bc zsh bwm-ng htop atool aria2 exa unzip \
                                kvantum materia-kde kvantum-theme-materia materia-gtk-theme \
                                gtk-engine-murrine latte-dock-git mono pnpm-bin ferdi-bin \
                                gnupg ulauncher ulauncher-theme-arc-dark-git dropbox nextcloud-client \
                                papirus-icon-theme spotify teams slack-desktop mailspring \
                                virtualbox virtualbox-guest-iso virtualbox-ext-oracle \
                                rustup gdb lldb kgpg kwrite plasma5-applets-virtual-desktop-bar-git \
                                discover baobab dotnet-host dotnet-runtime dotnet-runtime-3.1 dotnet-sdk \
                                dotnet-sdk-3.1 dotnet-targeting-pack dotnet-targeting-pack-3.1 aspnet-runtime \
                                aspnet-runtime-3.1 aspnet-targeting-pack aspnet-targeting-pack-3.1

    # installing this separately because it seems to no longer well and I wanted to be able to comment it out
    pamac install --no-confirm superpaper

    # get that rust
    rustup toolchain install stable
    rustup target add i686-unknown-linux-gnu

    # install some AUR things that take a while to compile
    # mono-git build-depends on mono which is installed in the prior steps
    pamac install --no-confirm mono-git wine-valve proton

    # set icons this way cuz I can
    /usr/lib/plasma-changeicons Papirus-Dark
fi

LAST_SNAPSHOT=`borg list --short --last 1 "${REPO_PATH}"`
echo "${LAST_SNAPSHOT}"
# borg --progress extract --strip-components 2 "${REPO_PATH}::${LAST_SNAPSHOT}" home/${USER}/{Desktop,Documents,Music,techsupport,Videos,VirtualBox\ VMs,Downloads,Development,Dropbox,.ssh,.gnupg,.gitconfig,/.config/BraveSoftware/Brave-Browser,.config/Ferdi,.config/latte,.config/superpaper}

borg --progress extract --strip-components 2 "${REPO_PATH}::${LAST_SNAPSHOT}" home/${USER}/.config/latte