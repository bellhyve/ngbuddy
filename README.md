% ngbuddy(8) | System Manager's Manual
% Daniel J. Bell
% July 8, 2024

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

**ngbuddy** ("Netgraph Buddy") is an rc.d script for managing netgraph(4) in mixed vm and jail environments. Netgraph provides a more flexible networking solution compared to the traditional if_bridge/epair/tap setup, a clearer and shorter list of virtual devices, and performance benefits for some workloads.

**rc.conf** variables prefixed by **ngbuddy_** are used to manage ng_bridge(4) and ng_eiface(4) devices upon service start (and system boot). Additional tools assist with jail interface management, configuring vm-bhyve, naming vm-bhyve sockets, displaying basic statistics, and determine stable MAC addresses to help avoid collisions.

# QUICK START EXAMPLE

The following commands will configure a system for netgraph.

**service ngbuddy enable**
:    Sets **rc.conf** variables to enable the ngbuddy service. If no bridge definitions are set, the following default bridge definitions will be added: \
:    _public_: A bridge interface associated with the host system's current default route, allowing guests to interact with the existing network. \
:    _private_: A bridge linked to a new virtual interface named **nghost0**, suitable for host-only or NAT network with your guests. \

```sh
	ngbuddy_enable="YES"
	ngbuddy_public_if="em0"
	ngbuddy_private_if="nghost0"
```

**service ngbuddy start**
:    Creates bridges and interfaces defined in **rc.conf**.

**service ngbuddy vmconf**
:    Adds our _public_ and _private_ bridges to the vm(8) configuration, as a substitute for the **vm switch ...*** commands.

To get the most out of the _private_ bridge, configure **nghost0** with an IP address and add a NAT service to allow your guests to have access to the network. See the **examples** in the **ngbuddy** repository for demo scripts.

# SUBCOMMANDS

Subcommands are called using **service ngbuddy** _SUBCOMMAND_. Note that all commands rely on ngctl(8) and require root permissions.

**enable**
:    Enable the **ngbuddy** service. If no bridges are defined, a _public_ and _private_ bridge will be created. See _QUICK START EXAMPLE_ above for details.

**start**
:    Load the bridge and eiface options configured in **rc.conf**. See _RC.CONF VARIABLES_ below for a complete list of options.

**stop**
:    Destroy all ng_bridge(4) and ng_eiface(4) devices, even if they were not created with **ngbuddy**.

**restart**
:    Stop, then start.

**status**
:    Print a list of ng_bridge(4), ng_eiface(4), and ng_socket(4) devices and basic usage statistics.

**bridge** _bridge_ _interface_
:    Create a bridge and an associated **rc.conf** entry. If the _interface_ exists, _bridge_ will be associated with it. Otherwise, _interface_ will be created as a new eiface node.

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
:    Add the bridges configured in **rc.conf** to the vm(8) configuration, e.g., **/vm/.config/system.conf**.

**vmname**
:    Name ng_socket(4) devices associated with bhyve instances running via vm(8).

# RC.CONF VARIABLES

The following variables can be manually configured. Some of the above subcommands will use sysrc(8) to configure rc.conf with the following variables for persistent configuration on service restart or system reboot.

_ngbuddy_enable_
:    Set to _YES_ to enable the service. 

_ngbuddy\_(_BRIDGE_)\_if_
:    Link a new ng_bridge(4) device named _BRIDGE_ to the indicated interface, e.g., _eth0_. If the interface already exists, link it to the new bridge and disable LRO/TSO. If the interface does not exist, create it as an ng_eiface(4) device. This variable will be set with the **bridge** and **unbridge** subcommands.

_ngbuddy\_(_BRIDGE_)\_list_
:    A space delimited list of additional ng_eiface(4) devices that will be attached to _BRIDGE_ at startup. This variables will be set with the **create** and **destroy** subcommands.

_ngbuddy_set_mac_
:    If set to _YES_, eiface hardware addresses will be determined from a hash of the interface name, ensuring that the interfaces' MAC address are stable between hosts. If set to a string besides _YES_, that string will be added to the MAC address generator's seed.

_ngbuddy_set_mac_prefix_
:    Override the default MAC address prefix of **58:9C:FC** (the OUI of the FreeBSD Foundation). For example, you can set _ngbuddy_set_mac_prefix="02"_ to minimize the risk of collisions. _ngbuddy_set_mac_ must also be enabled to use this feature.

_ngbuddy_set_mac_hash_
:    Override the default hash command of **sha1** with the command indicated. The command's output will receive the seed through standard input (see _ngbuddy_set_mac_) and must return enough hexadecimal characters to complete the MAC address.

# FILES
**/usr/local/etc/rc.d/ngbuddy**
:    The Netgraph Buddy run control script.

**/usr/local/share/ngbuddy/ngbuddy-status.awk**
:    Helper for **service ngbuddy status**

**/usr/local/share/ngbuddy/ngbuddy-mmd.awk**
:    An alternative to **ngctl dot** that creates a Mermaid-JS color diagram of netgraph nodes.

# EXAMPLES
For examples and demo scripts, see **examples** at: https://github.com/bellhyve/netgraph-buddy

**Example 1: Quickly deploy a VNET jail with netgraph using jail.conf.d**

The following steps will configure a jail attached to the interface associated with the host's current default route, likely your LAN, using DHCP.

First, set up Netgraph Buddy: \
- **service ngbuddy enable** \
- **service ngbuddy start** \
- Append **examples/devfs.rules** to **/etc/devfs.rules** \

Next, create a new jail: \
- Set up a FreeBSD base: **bsdinstall jail /jail/my_jail** \
- Enable DHCP in the jail: **sysrc -f /jail/my_jail/etc/rc.conf ifconfig_DEFAULT=SYNCDHCP** \

Configure the jail configuration: \
- Copy **examples/jail_skel.conf** to **/etc/jail.conf.d/my_jail.conf** \
- In **my_jail.conf** after the comments, change the word **jail_skel** to your jail's name, **my_jail** \
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

# SEE ALSO

jail(8), netgraph(4), ng_bridge(4), ngctl(8), ng_eiface(4), ng_socket(4), vm(8)

# HISTORY

Netgraph Buddy was originally developed as an internal tool for Bell Tower Integration's private cloud in August 2022.
