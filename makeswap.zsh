#!/usr/bin/zsh

${SWAPFILE}="/swapfile"

if [ -f ${SWAPFILE} ];
then
    sudo swapoff ${SWAPFILE}
    sudo rm -fv ${SWAPFILE}
fi

sudo dd status=progress if=/dev/zero of=${SWAPFILE} bs=1M count=$((32 * 1024)) && \
    sudo chmod 600 /swapfile && \
    sudo mkswap -U clear /swapfile && \
    sudo swapon /swapfile && \
    sudo findmnt -no UUID -T /swapfile && \
    sudo filefrag -v /swapfile | awk '$1=="0:" {print substr($4, 1, length($4)-2)}' && \
    cat <<-EOF | sudo tee /etc/dracut.conf.d/resume.conf
add_dracutmodules+=" resume "
install_items+=" /usr/lib/systemd/system/systemd-hibernate-resume.service "
EOF