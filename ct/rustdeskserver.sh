#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/mrboros/proxmox-helper-scripts/refs/heads/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# Co-Author: mrboros


function header_info {
clear
cat <<"EOF"
 ____            _   ____            _      ____                           
|  _ \ _   _ ___| |_|  _ \  ___  ___| | __ / ___|  ___ _ ____   _____ _ __ 
| |_) | | | / __| __| | | |/ _ \/ __| |/ / \___ \ / _ \ '__\ \ / / _ \ '__|
|  _ <| |_| \__ \ |_| |_| |  __/\__ \   <   ___) |  __/ |   \ V /  __/ |   
|_| \_\\__,_|___/\__|____/ \___||___/_|\_\ |____/ \___|_|    \_/ \___|_|    

EOF
}
header_info
echo -e "Loading..."
APP="Rustdesk Server"
var_disk="2"
var_cpu="2"
var_ram="2048"
var_os="debian"
var_version="12"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="yes"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="yes"
  VERB="yes"
  echo_default
}

function update_script() {
    header_info

    if [[ ! -x /usr/bin/hbbr ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    RELEASE=$(curl -s https://api.github.com/repos/rustdesk/rustdesk-server/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
    if [[ "${RELEASE}" != "$(cat /opt/rustdesk_version.txt)" ]] || [[ ! -f /opt/rustdesk_version.txt ]]; then
        msg_info "Stopping $APP"
        systemctl stop rustdesk-hbbr
        systemctl stop rustdesk-hbbs
        msg_ok "Stopped $APP"

        msg_info "Updating $APP to v${RELEASE}"
        TEMPDIR=$(mktemp -d)
        wget -q "https://github.com/rustdesk/rustdesk-server/releases/download/${RELEASE}/rustdesk-server-hbbr_${RELEASE}_amd64.deb" -P $TEMPDIR
        wget -q "https://github.com/rustdesk/rustdesk-server/releases/download/${RELEASE}/rustdesk-server-hbbs_${RELEASE}_amd64.deb" -P $TEMPDIR
        wget -q "https://github.com/rustdesk/rustdesk-server/releases/download/${RELEASE}/rustdesk-server-utils_${RELEASE}_amd64.deb" -P $TEMPDIR
        $STD dpkg -i $TEMPDIR/*.deb
        msg_ok "Updated $APP to v${RELEASE}"

        msg_info "Cleaning Up"
        rm -rf $TEMPDIR
        msg_ok "Cleanup Completed"

        echo "${RELEASE}" >/opt/rustdesk_version.txt
        msg_ok "Update Successful"
    else
        msg_ok "No update required. ${APP} is already at v${RELEASE}"
    fi
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}${IP}${CL}"