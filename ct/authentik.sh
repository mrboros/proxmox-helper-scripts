#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/mrboros/proxmox-helper-scripts/refs/heads/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: remz1337
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://goauthentik.io/
# Co-Author: mrboros

function header_info {
clear
cat <<"EOF"
               __  __               __  _ __  
  ____ ___  __/ /_/ /_  ___  ____  / /_(_) /__
 / __ `/ / / / __/ __ \/ _ \/ __ \/ __/ / //_/
/ /_/ / /_/ / /_/ / / /  __/ / / / /_/ / ,<   
\__,_/\__,_/\__/_/ /_/\___/_/ /_/\__/_/_/|_| 
EOF
}
header_info
echo -e "Loading..."
APP="Authentik"
var_disk="12"
var_cpu="6"
var_ram="8192"
var_os="debian"
var_version="12"
var_unprivileged="1"
var_password="authentik"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="$var_unprivileged"
  PW="$var_password"
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
  check_container_storage
  check_container_resources
  if [[ ! -f /etc/systemd/system/authentik-server.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/goauthentik/authentik/releases/latest | grep "tarball_url" | awk '{print substr($2, 2, length($2)-3)}')
  if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
    msg_info "Stopping ${APP}"
    systemctl stop authentik-server
    systemctl stop authentik-worker
    msg_ok "Stopped ${APP}"

    msg_info "Building ${APP} website"
    mkdir -p /opt/authentik
    wget -qO authentik.tar.gz "${RELEASE}"
    tar -xzf authentik.tar.gz -C /opt/authentik --strip-components 1 --overwrite
    rm -rf authentik.tar.gz
    cd /opt/authentik/website
    $STD npm install
    $STD npm run build-bundled
    cd /opt/authentik/web
    $STD npm install
    $STD npm run build
    msg_ok "Built ${APP} website"

    msg_info "Building ${APP} server"
    cd /opt/authentik
    go mod download
    go build -o /go/authentik ./cmd/server
    go build -o /opt/authentik/authentik-server /opt/authentik/cmd/server/
    msg_ok "Built ${APP} server"

    msg_info "Installing Python Dependencies"
    cd /opt/authentik
    $STD poetry install --only=main --no-ansi --no-interaction --no-root
    $STD poetry export --without-hashes --without-urls -f requirements.txt --output requirements.txt
    $STD pip install --no-cache-dir -r requirements.txt
    $STD pip install .
    msg_ok "Installed Python Dependencies"

    msg_info "Updating ${APP} to v${RELEASE} (Patience)"
    cp -r /opt/authentik/authentik/blueprints /opt/authentik/blueprints
    $STD bash /opt/authentik/lifecycle/ak migrate
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP} to v${RELEASE}"

    msg_info "Starting ${APP}"
    systemctl start authentik-server
    systemctl start authentik-worker
    msg_ok "Started ${APP}"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:9000/if/flow/initial-setup/${CL} \n"
