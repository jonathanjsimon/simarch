#!/usr/bin/zsh

#set -x

BORG_RESTORE=0
REPO_PATH=""
PASSPHRASE=""
CONFIG=1
DATA=1

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
        --configonly)
            CONFIG=1
            DATA=0
        ;;
        --dataonly)
            CONFIG=0
            DATA=1
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
            read -s "PASSPHRASE?Repo passphrase (${REPO_PATH}): "
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

if [ ${CONFIG} -eq 1 ];
then
    echo "Restoring configurations from ${REPO_PATH}::${LAST_SNAPSHOT}..."
    borg --progress extract --strip-components 2 "${REPO_PATH}::${LAST_SNAPSHOT}" home/${USER}/{.ac_domain_smb_credentials,ac_shares.zsh,.dotfiles,.gitconfig,.gitkraken,.gnupg,.histfile,.ssh,.vscode,.config/BraveSoftware/Brave-Browser,.config/Code,.config/deluge,.config/Ferdium,.config/GitKraken,.config/JetBrains,.config/obsidian,.config/polybar,.config/remmina,.config/Slack,.config/superpaper,.config/touchegg,.config/ulauncher,.config/yay,.local/share/plasma/plasmoids,.config/1Password,.local/share/remmina,.local/share/Steam/,.local/share/ulauncher,.local/share/Vorta}
fi

if [ ${DATA} -eq 1 ];
then
    echo "Restoring files from ${REPO_PATH}::${LAST_SNAPSHOT}..."
    borg --progress extract --strip-components 2 "${REPO_PATH}::${LAST_SNAPSHOT}" home/${USER}/{Desktop,Documents,Development,Downloads,Music,techsupport,Videos,VirtualBox\ VMs}
fi
popd
