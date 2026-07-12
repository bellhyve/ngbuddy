#!/bin/sh
#
# ten_jails.sh
#
# Demo for a blank FreeBSD ZFS VM: install ngbuddy from packages and deploy
# ten jails quickly — five "public" jails on the host's default route, and five
# "private" jails behind the host as DHCP server and NAT gateway.
#
# Requirements: network access, ZFS root, root privileges.
#
# Suggested image (or any current FreeBSD ZFS VM/cloud image):
#
#	https://download.freebsd.org/ftp/releases/VM-IMAGES/
#
# WARNING: Overwrites jail-related files and network settings (pf.conf,
# dnsmasq.conf, jail list). Use only on a disposable system.

JAIL_DS=zroot/jail
PRIVATE_NET=10.2.19
EXAMPLES=/usr/local/share/ngbuddy/examples
RELEASE=$(uname -r | sed 's/-p[0-9]*//')
ARCH=$(uname -m)

set -eux

pkg install -y ngbuddy dnsmasq

# Example configs shipped with the package
cp "$EXAMPLES/jail_skel.conf" /etc/jail.conf.d/
grep -q devfsrules_jail_dhcp /etc/devfs.rules 2>/dev/null || \
	cat "$EXAMPLES/devfs.rules" >> /etc/devfs.rules
service devfs restart

service ngbuddy enable
service ngbuddy start

# Jail template from matching FreeBSD base set
JAIL_SKEL_DS=$JAIL_DS/jail_skel
JAIL_SKEL_CONF=/etc/jail.conf.d/jail_skel.conf
zfs create -p "$JAIL_SKEL_DS"
zfs set mountpoint=/jail "$JAIL_DS"
JAIL_DIR=/jail/jail_skel
BASE_TXZ=base.txz
if [ ! -e "$BASE_TXZ" ]; then
	fetch -o "$BASE_TXZ" \
		"https://download.freebsd.org/ftp/releases/${ARCH}/${ARCH}/${RELEASE}/base.txz"
fi
if [ ! -e "$JAIL_DIR/etc/rc.conf" ]; then
	mkdir -p "$JAIL_DIR"
	tar -xJf "$BASE_TXZ" -C "$JAIL_DIR"
fi
sysrc -f "$JAIL_DIR/etc/rc.conf" ifconfig_DEFAULT=SYNCDHCP
zfs snapshot "${JAIL_SKEL_DS}@a"

# Five public + five private jails
for j in $(jot 5); do
	jname=pubjail$j
	zfs clone "${JAIL_SKEL_DS}@a" "$JAIL_DS/$jname"
	sed "s/jail_skel/$jname/g" "$JAIL_SKEL_CONF" > "/etc/jail.conf.d/$jname.conf"
	sysrc jail_list+="$jname"

	jname=prijail$j
	zfs clone "${JAIL_SKEL_DS}@a" "$JAIL_DS/$jname"
	sed -e "s/jail_skel/$jname/g" -e 's/public/private/' \
		"$JAIL_SKEL_CONF" > "/etc/jail.conf.d/$jname.conf"
	sysrc jail_list+="$jname"
done

# Private-jail networking: NAT + dnsmasq (DHCP/DNS) on nghost0
EXT_IF=$(netstat -rn | awk '$1 == "default" { print $4; exit }')
cat > /etc/pf.conf << EOF
nat on $EXT_IF from ${PRIVATE_NET}.0/24 to any -> ($EXT_IF)
EOF
cat > /usr/local/etc/dnsmasq.conf << EOF
interface=nghost0
bind-interfaces
dhcp-range=${PRIVATE_NET}.100,${PRIVATE_NET}.199,12h
dhcp-option=option:router,${PRIVATE_NET}.1
domain-needed
bogus-priv
EOF

sysrc gateway_enable=YES pf_enable=YES dnsmasq_enable=YES
sysrc jail_enable=YES jail_parallel_start=YES
sysrc ifconfig_nghost0="inet ${PRIVATE_NET}.1/24 up"

ifconfig nghost0 inet "${PRIVATE_NET}.1/24" up
sysctl net.inet.ip.forwarding=1

service pf start
service dnsmasq start

service jail start
