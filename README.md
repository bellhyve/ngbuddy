% ngbuddy(8) | System Manager's Manual
% Daniel J. Bell
% July 12, 2026

# NAME

**ngbuddy** - Simplified netgraph(4) manager for jail(8) and bhyve(8)

# SYNOPSIS

**service ngbuddy enable** \
**service ngbuddy start** \
**service ngbuddy stop** \
**service ngbuddy restart** \
**service ngbuddy status**

**service ngbuddy bridge** _bridge_ _interface_ \
**service ngbuddy unbridge** _bridge_

**service ngbuddy jail** _interface_ [_bridge_] \
**service ngbuddy unjail** _interface_ [_jail_] \
**service ngbuddy create** _interface_ [_bridge_] \
**service ngbuddy destroy** _interface_

**service ngbuddy vmconf** \
**service ngbuddy vmname**

# DESCRIPTION

**ngbuddy** ("Netgraph Buddy") is an rc.d script for managing netgraph(4) in mixed VM and jail environments. Netgraph provides a more flexible networking solution than the traditional if_bridge/epair/tap setup, offering a clearer and shorter list of virtual devices, and performance benefits for some workloads.

**rc.conf** variables prefixed by **ngbuddy_** are used to manage ng_bridge(4) and ng_eiface(4) devices on service start (and system boot). Additional tools assist with jail interface management, configuring vm-bhyve, naming vm-bhyve sockets, displaying basic statistics, and determining stable MAC addresses to help avoid collisions.

When a bridge is attached to an existing network interface (physical NIC or VLAN), **ngbuddy** connects that interface to the bridge with **uplink** hooks by default so the bridge does not learn outside-world MAC addresses. Guest and host eiface nodes use ordinary **link** hooks. When **service ngbuddy jail** or **create** attaches an eiface, **ngbuddy** also installs that interface's MAC on the bridge with **movehost** before any VNET handoff. That keeps unicast return traffic working for VNET jails on FreeBSD versions that cannot reliably learn MACs from moved **ng_eiface**(4) devices. Interface names in **rc.conf** should use the ifconfig(8) form (including dots for VLANs, e.g. **re0.42**); netgraph node names convert dots to underscores automatically.

# QUICK START EXAMPLE

The following commands will configure a system for netgraph.

**service ngbuddy enable**
:    Sets **rc.conf** variables to enable the ngbuddy service. If no bridge definitions are set, the following default bridge definitions will be added: \
:    _public_: A bridge associated with the host system's current default route, allowing guests to interact with the existing network. \
:    _private_: A bridge linked to a new virtual interface named **nghost0**, suitable for host-only or NAT networking with your guests. \

```sh
	ngbuddy_enable="YES"
	ngbuddy_public_if="em0"
	ngbuddy_private_if="nghost0"
```

**service ngbuddy start**
:    Creates bridges and interfaces defined in **rc.conf**.

**service ngbuddy vmconf**
:    Adds the _public_ and _private_ bridges to the vm(8) configuration, as a substitute for the **vm switch** commands.

To get the most out of the _private_ bridge, configure **nghost0** with an IP address and add a NAT service so guests can reach the network. See the **examples** in the **ngbuddy** repository for demo scripts.

# SUBCOMMANDS

Subcommands are called using **service ngbuddy** _SUBCOMMAND_. Note that all commands rely on ngctl(8) and require root privileges.

**enable**
:    Enable the **ngbuddy** service. If no bridges are defined, a _public_ and _private_ bridge will be created. See _QUICK START EXAMPLE_ above for details.

**start**
:    Create the bridge and eiface devices configured in **rc.conf**. See _RC.CONF VARIABLES_ below for a complete list of options.

**stop**
:    Destroy all ng_bridge(4) and ng_eiface(4) devices, even if they were not created with **ngbuddy**.

**restart**
:    Stop, then start.

**status**
:    Print a list of ng_bridge(4) devices, their attached peers, and basic traffic statistics.

**bridge** _bridge_ _interface_
:    Create a bridge and an associated **rc.conf** entry. If the _interface_ already exists, _bridge_ is attached to it with uplink hooks (and LRO/TSO are disabled on that interface). Otherwise, _interface_ is created as a new eiface node.

**unbridge** _bridge_
:    Remove the indicated bridge from netgraph and **rc.conf**.

**jail** _interface_ [_bridge_]
:    Create a new eiface associated with the indicated _bridge_. If only one ng_bridge(4) is present, _bridge_ may be omitted.

**unjail** _interface_ [_jail_]
:    Shut down the eiface associated with the indicated _jail_. If the _interface_ matches the jail name, _jail_ may be omitted.

**create** _interface_ [_bridge_]
:    Create a new eiface associated with the indicated _bridge_ and add it to **rc.conf** so it will be created on startup. If only one bridge is configured, _bridge_ may be omitted.

**destroy** _interface_
:    Shut down the indicated eiface and remove it from **rc.conf**.

**vmconf**
:    Add the bridges configured in **rc.conf** to the vm(8) configuration, e.g. **/vm/.config/system.conf**.

**vmname**
:    Name ng_socket(4) devices associated with bhyve instances running via vm(8).

# RC.CONF VARIABLES

The following variables can be configured manually. Some of the subcommands above use sysrc(8) to write these variables for persistent configuration across service restarts and system reboots.

_ngbuddy_enable_
:    Set to _YES_ to enable the service.

_ngbuddy\_(_BRIDGE_)\_if_
:    Associate a new ng_bridge(4) device named _BRIDGE_ with the indicated interface, e.g. _em0_ or _re0.42_. If the interface already exists, attach it to the bridge with uplink hooks and disable LRO/TSO. If the interface does not exist, create it as an ng_eiface(4) device. This variable is set by the **bridge** and **unbridge** subcommands.

_ngbuddy\_(_BRIDGE_)\_list_
:    A space-delimited list of additional ng_eiface(4) devices attached to _BRIDGE_ at startup. This variable is set by the **create** and **destroy** subcommands.

_ngbuddy_max_retries_
:    Maximum number of occupied bridge hooks to skip while creating an eiface. The default is **1024**.

_ngbuddy_public_hooks_
:    Hook style used when attaching an existing NIC or VLAN to a public bridge. The default is **uplink** (**uplink1**/**uplink2**), which avoids learning outside-world MAC addresses. Set to **link** to use ordinary **link0**/**link1** hooks instead (unknown unicast is flooded to every bridge port).

_ngbuddy_set_mac_
:    If set to _YES_, eiface hardware addresses are derived from a hash of the interface name so MAC addresses stay stable across hosts. If set to any string other than _YES_, that string is added to the MAC address generator's seed.

_ngbuddy_set_mac_prefix_
:    Override the default MAC address prefix of **58:9C:FC** (the OUI of the FreeBSD Foundation). For example, set _ngbuddy_set_mac_prefix="02"_ to minimize the risk of collisions. _ngbuddy_set_mac_ must also be enabled to use this feature.

_ngbuddy_set_mac_hash_
:    Override the default hash command of **sha1** with the command indicated. The command receives the seed on standard input (see _ngbuddy_set_mac_) and must return enough hexadecimal characters to complete the MAC address.

# FILES
**/usr/local/etc/rc.d/ngbuddy**
:    The Netgraph Buddy run control script.

**/usr/local/share/ngbuddy/ngbuddy-status.awk**
:    Helper for **service ngbuddy status**.

**/usr/local/share/ngbuddy/ngbuddy-mmd.awk**
:    An alternative to **ngctl dot** that creates a Mermaid-JS color diagram of netgraph nodes.

# EXAMPLES
For examples and demo scripts, see **examples** at: https://github.com/bellhyve/netgraph-buddy

**Example 1: Quickly deploy a VNET jail with netgraph using jail.conf.d**

The following steps configure a jail attached to the interface associated with the host's current default route (typically your LAN), using DHCP.

First, set up Netgraph Buddy: \
- **service ngbuddy enable** \
- **service ngbuddy start** \
- Append **examples/devfs.rules** to **/etc/devfs.rules** \

Next, create a new jail: \
- Set up a FreeBSD base: **bsdinstall jail /jail/my_jail** \
- Enable DHCP in the jail: **sysrc -f /jail/my_jail/etc/rc.conf ifconfig_DEFAULT=SYNCDHCP** \

Configure the jail: \
- Copy **examples/jail_skel.conf** to **/etc/jail.conf.d/my_jail.conf** \
- In **my_jail.conf**, after the comments, change the word **jail_skel** to your jail's name, **my_jail** \
- Run: **service jail start my_jail** \

To create more jails, you can: \
- Copy **/jail/my_jail/** to **/jail/new_jail1/** \
- Copy **/etc/jail.conf.d/my_jail.conf** to **new_jail1.conf** \
- Edit the new configuration as above and change the word **my_jail** to **new_jail1** \
- Run: **service jail start new_jail1** \
- And repeat as desired. \

**Example 2: An rc.conf example for a slightly more complex setup**

```sh
ngbuddy_enable="YES"
ngbuddy_lan_if="igb0"
ngbuddy_private0_if="ng0"
ngbuddy_private0_list="j1p0 j2p0"
ngbuddy_private1_if="ng1"
ngbuddy_private1_list="j1p1 j2p1"
ngbuddy_tenant_lan_if="igb1"
ngbuddy_tenant_wan_if="ix1"
ngbuddy_wan_if="ix0"
ngbuddy_set_mac="belltower"
ngbuddy_set_mac_prefix="02"
ngbuddy_set_mac_hash="sha256"
```

VLAN interfaces work the same way; use the ifconfig name with a dot:

```sh
ngbuddy_public_if="re0.42"
```

**Example 3: Initial status of the above configuration**

```sh
lan
  igb0 (upper): RX 0B, TX 0B
  igb0 (lower): RX 0B, TX 0B
private0
  j2p0: RX 0B, TX 0B
  j1p0: RX 0B, TX 0B
  ng0: RX 0B, TX 0B
private1
  j2p1: RX 0B, TX 0B
  j1p1: RX 0B, TX 0B
  ng1: RX 0B, TX 0B
tenant_lan
  igb1 (upper): RX 0B, TX 0B
  igb1 (lower): RX 0B, TX 0B
tenant_wan
  ix1 (upper): RX 0B, TX 0B
  ix1 (lower): RX 0B, TX 0B
wan
  ix0 (upper): RX 30.69 KB, TX 46.16 KB
  ix0 (lower): RX 46.32 KB, TX 30.92 KB
```

# NOTES

These scripts were developed to assist with new netgraph features in **vm-bhyve 1.5+**, and were inspired by the **/usr/share/examples/jails/jng** example script and additional examples by Klara Systems.

See ng_bridge(4) for details on **link** and **uplink** hooks. Physical and VLAN uplinks are attached first so unknown unicast frames are forwarded toward the outside network rather than flooded to every guest. Because uplink-first bridges only deliver unknown unicast to uplink hooks, guest MAC entries must exist for return traffic. **ngbuddy** therefore pre-seeds each eiface MAC with **movehost** when the interface is created, which is required for full VNET jail connectivity (static or DHCP) on FreeBSD 14.x.

# SEE ALSO

jail(8), netgraph(4), ng_bridge(4), ngctl(8), ng_eiface(4), ng_ether(4), ng_socket(4), vm(8)

# HISTORY

Netgraph Buddy was originally developed as an internal tool for Bell Tower's private cloud in August 2022.

# AUTHORS

Daniel J. Bell <_bellhyve@zelta.space_>
