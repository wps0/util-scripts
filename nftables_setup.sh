#!/bin/bash
NFT_SCRIPTS_DIR="/etc/nftables"
NFT_GLOBAL_CONFIG="/etc/nftables.conf"
sudo mkdir -p $NFT_SCRIPTS_DIR || exit
sudo cp $NFT_GLOBAL_CONFIG $NFT_GLOBAL_CONFIG.bk || exit

sed  "/flush ruleset/a include \"$NFT_SCRIPTS_DIR/*.nft\"" /etc/nftables.conf | sudo dd of=/etc/nftables.conf || exit

sudo systemctl start nftables
sudo systemctl enable nftables


# Server setup
sudo systemctl set-default multi-user.target
sudo systemctl isolate multi-user.target
