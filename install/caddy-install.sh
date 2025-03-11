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

msg_info "Installing Dependencies"
$STD apt-get install -y {debian-keyring,debian-archive-keyring,apt-transport-https,gpg,curl,sudo,mc}
msg_ok "Installed Dependencies"

msg_info "Installing Caddy"
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' >/etc/apt/sources.list.d/caddy-stable.list
$STD apt-get update
$STD apt-get install -y caddy
msg_ok "Installed Caddy"

msg_info "Installing xCaddy"
msg_info "Installing dependency: Golang"
set +o pipefail
temp_file=$(mktemp)
golang_tarball=$(curl -s https://go.dev/dl/ | grep -oP 'go[\d\.]+\.linux-amd64\.tar\.gz' | head -n 1)
wget -q https://golang.org/dl/"$golang_tarball" -O "$temp_file"
tar -C /usr/local -xzf "$temp_file"
ln -sf /usr/local/go/bin/go /usr/local/bin/go
rm -f "$temp_file"
set -o pipefail
msg_ok "Installed dependency: Golang"

msg_info "Setting up xCaddy"
cd /root
RELEASE=$(curl -s https://api.github.com/repos/caddyserver/xcaddy/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
wget -q https://github.com/caddyserver/xcaddy/releases/download/${RELEASE}/xcaddy_${RELEASE:1}_linux_amd64.deb
$STD dpkg -i xcaddy_${RELEASE:1}_linux_amd64.deb
rm -rf /opt/xcaddy*
msg_ok "Set up xCaddy"

msg_info "Building Caddy with the required plugins"
$STD xcaddy build --with github.com/caddy-dns/cloudflare --with github.com/mholt/caddy-l4/layer4
systemctl stop caddy
cp ./caddy /usr/bin/caddy
systemctl start caddy
$STD systemctl status caddy
msg_ok "Built Caddy with the required plugins"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
