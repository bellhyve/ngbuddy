#!/bin/sh
#
# ten_jails.sh
#
# This script is intended to be used on a blank virtual machine to illustrate
# using Netgraph Buddy and ZFS to very quickly deploy ten jails in different
# ways. There are no requirements besides a network connection, a FreeBSD base
# package, and Netgraph Buddy.
#
# Netgraph Buddy will use jail.conf to create five "public" jails associated
# with a system's default route and 5 "private" jails which use the host as a
# DHCP server and router.
#
# This script is intended for use on an empty system with ZFS, such as the
# FreeBSD 140 ZFS VM image:
#
#	https://download.freebsd.org/ftp/releases/VM-IMAGES/14.0-RELEASE/amd64/Latest/FreeBSD-14.0-RELEASE-amd64-zfs.raw.xz
#
# WARNING: Several commands below will overwrite jail-related files and network
# settings; please use this script with caution.

JAIL_DS=zroot/jail
PRIVATE_NET=10.2.19

set -x
pkg install -y git-lite dhcpd

# Set up ngbuddy
# TODO: Replace with ngbuddy FreeBSD package.
git clone https://github.com/bellhyve/ngbuddy.git
cd ngbuddy
cp ngbuddy /usr/local/etc/rc.d/
cp ngbuddy.8 /usr/local/share/man/man8/
cp -r share/ngbuddy/ /usr/local/share/ngbuddy/
cp examples/jail_skel.conf /etc/jail.conf.d/
cat examples/devfs.rules >> /etc/devfs.rules
cd
service ngbuddy enable
service ngbuddy start

# Set up jail template
JAIL_SKEL_DS=$JAIL_DS/jail_skel
JAIL_SKEL_CONF=/etc/jail.conf.d/jail_skel.conf
zfs create -p $JAIL_SKEL_DS
zfs set mountpoint=/jail $JAIL_DS
JAIL_DIR=/jail/jail_skel
[ ! -e base.txz ] && fetch https://download.freebsd.org/ftp/releases/amd64/amd64/14.0-RELEASE/base.txz -q
[ ! -e $JAIL_DIR/etc/rc.conf ] && tar zxf base.txz -C $JAIL_DIR
sysrc -f $JAIL_DIR/etc/rc.conf ifconfig_DEFAULT=SYNCDHCP
zfs snapshot $JAIL_SKEL_DS@a

# Set up jails
for j in $(jot 5); do
	# Public
	jname=pubjail$j
	zfs clone $JAIL_SKEL_DS@a $JAIL_DS/$jname
	sed s/jail_skel/$jname/ $JAIL_SKEL_CONF > /etc/jail.conf.d/$jname.conf
	sysrc jail_list+=$jname

	# Private
	jname=prijail$j
	zfs clone $JAIL_SKEL_DS@a $JAIL_DS/$jname
	sed -e s/jail_skel/$jname/ -e s/public/private/ $JAIL_SKEL_CONF > /etc/jail.conf.d/$jname.conf
	sysrc jail_list+=$jname
done

# Public jails can be started at this point;
# no additional configuration required

# Set up networking for private jails
DNS_SERVER=$(grep -o '[0-9].*' /etc/resolv.conf)
EXT_IF=$(netstat -rn|awk '$1 == "default"{print $4}')
echo "nat on $EXT_IF from $PRIVATE_NET.0/24 to any -> ($EXT_IF)" > /etc/pf.conf
cat > /usr/local/etc/dhcpd.conf << EOF
option domain-name-servers $DNS_SERVER;
option subnet-mask 255.255.255.0;
subnet $PRIVATE_NET.0 netmask 255.255.255.0 {
  range  $PRIVATE_NET.101 $PRIVATE_NET.199;
  option routers $PRIVATE_NET.1;
}
EOF
# Enable and start required network-related services for private jails
sysrc gateway_enable=YES pf_enable=YES dhcpd_enable=YES dhcpd_flags=nghost0
sysrc jail_enable=YES jail_parallel_start=YES
sysrc ifconfig_nghost0="inet $PRIVATE_NET.1/24 up"
# The next two lines are required before the next reboot for private jails
ifconfig nghost0 inet $PRIVATE_NET.1/24 up
sysctl net.inet.ip.forwarding=1
# Start firewall and DHCP server for private jails
service pf start
service dhcpd start

# Start ten jails
service jail start
