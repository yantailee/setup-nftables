#!/bin/sh

white_list_fname=/etc/nftables/domestic_white_list
#white_list_fname=./domestic_white_list

##### ホワイトリスト作成

### ファイル作成
cat <<EOF > ${white_list_fname}
### ${white_list_fname}
define domestic_white_list = {
EOF
cp -p jp.txt jp.txt.bkup
touch ${white_list_fname}
curl https://ipv4.fetus.jp/jp.txt > jp.txt
#curl https://ipv4.fetus.jp/jp.txt | grep -v '^#' | awk -F, '$1!= "" { print $1FS}' >> ${white_list_fname}
cat ./jp.txt | grep -v '^#' | awk -F, '$1!= "" { print $1FS}' >> ${white_list_fname}
cat <<EOF >> ${white_list_fname}
192.168.0.0/16,
10.0.0.0/8,
172.16.0.0/12,
}
EOF
### 
systemctl enable nftables.service
###
##### ExecReload=/usr/sbin/nft 'flush ruleset; include "/etc/nftables/nftables.conf";'
sed 's/^ExecReload=\/usr\/sbin\/nft -f \/etc\/nftables.conf/ExecReload=\/usr\/sbin\/nft '\''flush ruleset; include "\/etc\/nftables\/nftables.conf";'\''/' /usr/lib/systemd/system/nftables.service

#
mkdir -p /etc/nftables
cat <<EOF > /etc/nftables/nftables.conf
flush ruleset
 
include "/etc/nftables/domestic_white_list"
 
table ip filter {
  set country_accept {
    type ipv4_addr; flags interval;
    elements = $domestic_white_list
  }
 
  chain INPUT {
    type filter hook input priority 0; policy drop;
 
    iifname "lo" counter accept
 
    ct state established,related counter accept
 
    ct state new tcp dport 80 ip saddr @country_accept counter accept
    ct state new tcp dport 443 ip saddr @country_accept counter accept
    ct state new tcp dport 22 ip saddr @country_accept counter accept
 
    icmp type echo-reply counter accept
    icmp type destination-unreachable counter accept
    icmp type time-exceeded counter accept
  }
 
  chain FORWARD {
    type filter hook forward priority 0; policy drop;
  }
 
  chain OUTPUT {
    type filter hook output priority 0; policy accept;
  }
}
 
# EOF
EOF
### sshによるrootログインを禁止
sed 's/^#PermitRootLogin/PermitRootLogin/' /etc/ssh/sshd_config
### 
apt -y install sudo vim
### 
update-alternatives --set editor /usr/bin/vim.basic
### 
localectl set-keymap --no-convert jp106
localectl set-locale LANG=ja_JP.utf8
localectl set-x11-keymap jp
