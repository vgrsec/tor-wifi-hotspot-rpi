#!/bin/bash

# check for root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

PWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# update software
echo "== Updating software"
apt-get update -y
apt-get dist-upgrade -y

# configure automatic updates
echo "== Configuring unattended upgrades"
apt-get install -y unattended-upgrades apt-listchanges
cp $PWD/etc/20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades

# Install WiFi Hotspot packages 
apt-get -y install hostapd udhcpd

# copy WiFi Hotspot configs
cp $PWD/etc/udhcpd.conf /etc/udhcpd.conf

# Copy in the config file to enable udhcpd
cp $PWD/etc/udhcpd /etc/default/udhcpd

# Copy in the systemd udhcpd.service file
cp $PWD/lib/systemd/system/udhcpd.service /lib/systemd/system/

# Tell systemd to enable the udhcpd.service
systemctl enable udhcpd.service

# Configure interfaces
cp $PWD/etc/network /etc/network

# Configure SSID
cp $PWD/etc/hostapd /etc/default/hostapd
cp $PWD/etc/hostapd.conf /etc/hostapd/hostapd.conf

# Configure NAT
cp $PWD/etc/sysctl.conf /etc/sysctl.conf

# Configure iptables
cp $PWD/etc/iptables.ipv4.nat /etc/iptables.ipv4.nat
touch /var/lib/misc/udhcpd.leases

# Launch Access Point 
systemctl unmask hostapd
service hostapd start
update-rc.d hostapd enable

# Launch DHCP Server
service udhcpd start
update-rc.d udhcpd enable

# Install Tor
apt-get install tor

# Configure Tor
cp $PWD/etc/torrc /etc/tor/torrc

# Configure iptables for Tor
iptables -F && iptables -t nat -F
iptables -t nat -A PREROUTING -i wlan0 -p udp --dport 53 -j REDIRECT --to-ports 53
iptables -t nat -A PREROUTING -i wlan0 -p tcp --syn -j REDIRECT --to-ports 9040
sh -c "iptables-save > /etc/iptables.ipv4.nat"

# Setup Tor Logs
touch /var/log/tor/notices.log
chown debian-tor /var/log/tor/notices.log && chmod 644 /var/log/tor/notices.log

# Launch Tor
service tor start
update-rc.d tor enable

# Install Monit
apt-get install monit

# Configure Monit
cp $PWD/etc/monitrc /etc/monit/monitrc

# Launch Monit
monit reload
update-rc.d monit enable

sleep 10
reboot

exit 0

