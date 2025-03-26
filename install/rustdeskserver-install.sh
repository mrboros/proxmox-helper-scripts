#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# Co-Author: mrboros

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Setup RustDesk"
$STD apt install curl
RELEASE=$(curl -s https://api.github.com/repos/rustdesk/rustdesk-server/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
TEMPDIR=$(mktemp -d)
wget -q "https://github.com/rustdesk/rustdesk-server/releases/download/${RELEASE}/rustdesk-server-hbbr_${RELEASE}_amd64.deb" -P $TEMPDIR
wget -q "https://github.com/rustdesk/rustdesk-server/releases/download/${RELEASE}/rustdesk-server-hbbs_${RELEASE}_amd64.deb" -P $TEMPDIR
wget -q "https://github.com/rustdesk/rustdesk-server/releases/download/${RELEASE}/rustdesk-server-utils_${RELEASE}_amd64.deb" -P $TEMPDIR
$STD dpkg -i $TEMPDIR/*.deb
echo "${RELEASE}" >/opt/rustdesk.txt
msg_ok "Setup RustDesk"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf $TEMPDIR
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"