#!/usr/bin/zsh

#set -x

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

for arg in "$@"
do
    case "$arg" in
        --borg=*)
            BORG_RESTORE=1
            REPO_PATH="${arg#--borg=}"
        ;;
    esac
done

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
        else
            exit 1
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
        exit 2
    fi
fi

pushd ~

LAST_SNAPSHOT=`borg list --short --last 1 "${REPO_PATH}"`

borg --progress extract --strip-components 2 "${REPO_PATH}::${LAST_SNAPSHOT}" home/${USER}/{.Xmodmap,.histfile,.ssh,.gnupg,.gitconfig,.dotfiles,.config/touchegg,.config/BraveSoftware/Brave-Browser,.config/Ferdium,.config/superpaper,.config/obsidian,.config/deluge,.config/Slack,.config/ulauncher,.local/share/ulauncher,.local/share/Vorta,Desktop,Documents,Music,techsupport,Videos,Downloads,Development,VirtualBox\ VMs,Dropbox}

popd
