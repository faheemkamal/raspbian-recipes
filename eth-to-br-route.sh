#!/bin/bash

# Share Eth with WiFi Hotspot
#
# This script is created to work with Raspbian Stretch
# but it can be used with most of the distributions
# by making few changes. 
#
# Make sure you have already installed `dnsmasq` and `hostapd`
# Please modify the variables according to your need
# Don't forget to change the name of network interface
# Check them with `ifconfig`

ip_address="192.168.2.1"
netmask="255.255.255.0"
dhcp_range_start="192.168.2.2"
dhcp_range_end="192.168.2.100"
dhcp_time="12h"
eth="eth0"
wlan="wlan0"
br="br0"
ssid="rpi-wifi"
psk="edithpiaf"


sudo killall wpa_supplicant &> /dev/null
sudo rfkill unblock wlan &> /dev/null
sleep 2


sudo brctl addbr br0
sudo brctl addif br0 eth1

echo "#static IP configuration

interface br0
static ip_address=192.168.2.1/24
static routers= 192.168.2.0" > /etc/dhcpcd.conf
sudo systemctl restart dhcpcd

iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT

sudo iptables -t nat -A POSTROUTING -o ppp0 -j MASQUERADE
# sudo iptables -t nat -A POSTROUTING -o $eth -j MASQUERADE

# sudo iptables -A FORWARD -i $eth -o $br -m state --state RELATED,ESTABLISHED -j ACCEPT  
# sudo iptables -A FORWARD -i $br -o $eth -j ACCEPT
sudo service iptables save
sudo service iptables restart 

sudo sysctl net.ipv4.ip_forward=1

echo "interface=$br \n\
bind-interfaces \n\
domain-needed \n\
bogus-priv \n\
dhcp-option=6,8.8.8.8,8.8.4.4 \n\
dhcp-range=$dhcp_range_start,$dhcp_range_end,$dhcp_time" > /etc/dnsmasq.conf

echo "interface=$wlan\n\
driver=nl80211\n\
ssid=$ssid\n\
hw_mode=g\n\
ieee80211n=1\n\
wmm_enabled=1\n\
macaddr_acl=0\n\
ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]\n\
channel=6\n\
auth_algs=1\n\
ignore_broadcast_ssid=0\n\
wpa=2\n\
wpa_key_mgmt=WPA-PSK\n\
wpa_passphrase=$psk\n\
rsn_pairwise=CCMP
bridge=br0" > /etc/hostapd/hostapd.conf

sudo systemctl stop hostapd
sudo hostapd /etc/hostapd/hostapd.conf &
sudo systemctl restart dnsmasq
