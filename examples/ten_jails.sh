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

# Override for non-zroot hosts, e.g. JAIL_DS=bootdev2/ngbuddy_smoke
JAIL_DS=${JAIL_DS:-zroot/jail}
JAIL_MNT=${JAIL_MNT:-/jail}
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
# ensure private bridge exists (enable only seeds defaults when none are set)
if ! ngctl list | awk '$2=="private" && $4=="bridge" { found=1 } END { exit !found }'; then
	service ngbuddy bridge private nghost0
fi

# Jail template from matching FreeBSD base set
JAIL_SKEL_DS=$JAIL_DS/jail_skel
JAIL_SKEL_CONF=/etc/jail.conf.d/jail_skel.conf
zfs create -p -o mountpoint="$JAIL_MNT" "$JAIL_DS" 2>/dev/null || \
	zfs set mountpoint="$JAIL_MNT" "$JAIL_DS"
zfs create -p "$JAIL_SKEL_DS"
JAIL_DIR=$JAIL_MNT/jail_skel
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
	sed -e "s/jail_skel/$jname/g" -e "s|/jail/|${JAIL_MNT}/|g" \
		"$JAIL_SKEL_CONF" > "/etc/jail.conf.d/$jname.conf"
	sysrc jail_list+="$jname"

	jname=prijail$j
	zfs clone "${JAIL_SKEL_DS}@a" "$JAIL_DS/$jname"
	sed -e "s/jail_skel/$jname/g" -e 's/"public"/"private"/' \
		-e "s|/jail/|${JAIL_MNT}/|g" \
		"$JAIL_SKEL_CONF" > "/etc/jail.conf.d/$jname.conf"
	sysrc jail_list+="$jname"
done

# Private-jail networking: NAT + dnsmasq (DHCP/DNS) on nghost0
EXT_IF=$(netstat -rn | awk '$1 == "default" { print $4; exit }')
cat > /etc/pf.conf << EOF
nat on $EXT_IF from ${PRIVATE_NET}.0/24 to any -> ($EXT_IF)
EOF
DNS_SERVER=$(awk '/^nameserver/{print $2; exit}' /etc/resolv.conf)
: "${DNS_SERVER:=1.1.1.1}"
# port=0: DHCP only (avoid clashing with host resolvers on :53)
cat > /usr/local/etc/dnsmasq.conf << EOF
interface=nghost0
bind-interfaces
except-interface=lo
port=0
dhcp-range=${PRIVATE_NET}.100,${PRIVATE_NET}.199,12h
dhcp-option=option:router,${PRIVATE_NET}.1
dhcp-option=option:dns-server,${DNS_SERVER}
EOF

sysrc gateway_enable=YES pf_enable=YES dnsmasq_enable=YES
sysrc jail_enable=YES jail_parallel_start=YES
sysrc ifconfig_nghost0="inet ${PRIVATE_NET}.1/24 up"

ifconfig nghost0 inet "${PRIVATE_NET}.1/24" up
sysctl net.inet.ip.forwarding=1

service pf start
service dnsmasq restart

service jail start
