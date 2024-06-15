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

**ngbuddy** ("Netgraph Buddy") is an rc.d script for managing netgraph(4) networks in mixed vm and jail environments. **rc.conf** variables prefixed by **ngbuddy_** are used to manage "permanent" ng_bridge(4) and ng_eiface(4) devices.  Additional tools assist with configuring vm-bhyve and naming their sockets for statistics and graphing.

# QUICK START EXAMPLE

The following commands will configure a system for netgraph in a way that is suitable for most common setups on systems where no netgraph configuration currently exists.

**service ngbuddy enable**
:    Set **rc.conf** variables and create a _public_ bridge interface associated with the host system's default route, then create a _private_ bridge linked to a virtual interface named **nghost0** suitable for a local or NAT interfaces. It will append three **rc.conf** lines similar to the following, which you can modify before starting the service:


```sh
	ngbuddy_enable="YES"
	ngbuddy_public_if="em0"
	ngbuddy_private_if="nghost0"
```

**service ngbuddy start**
:    This command creates the above interfaces.

**service ngbuddy vmconf**
:    Add the our "public" and "private" bridges to the vm(8) configuration.

If you'd like to use host-only or NAT interface, you must configure the newly created **nghost0** interface. For example, you may want to set up IP addresses, a DNS resolver, and a DHCP server.

Once post-configuration is to your liking, create jails or bhyve instances attached to your _public_ or _private_ bridges as you prefer. See the **jail_skel.conf** for assistance configuring jails.

# SUBCOMMANDS

Subcommands are called using **service ngbuddy _SUBCOMMAND_**. Note that all commands rely on ngctl(8) and require root permissions.

**enable**
:    Create a basic default **ngbuddy** configuration and enable the service.

**start**
:    Load the ng_bridge(4) and ng_eiface(4) options configured in **rc.conf**. See _RC.CONF VARIABLES_ below.

**stop**
:    Destroy all ng_bridge(4) and ng_eiface(4) devices, regardless of whether they were created with **ngbuddy** or not.

**restart**
:    Stop, then start.

**status**
:    Print a list of ng_bridge(4), ng_eiface(4), and ng_socket(4) devices and basic usage statistics.

**bridge** _bridge_ _interface_
:    Create a bridge and an associated **rc.conf** entry. If the _interface_ exists, _bridge_ will be associated with it. Otherwise, _interface_ will be created as a new ng_eiface(4) device.

**unbridge** _bridge_
:    Remove the indicated bridge from netgraph and **rc.conf**. This operation will fail if devices appear to be attached to it.

**jail** _interface_ [_bridge_] 
:    Create a new ng_eiface(4) associated with the indicated _bridge_. If only one ng_bridge(4) is present, _bridge_ may be omitted.

**unjail** _interface_ [_jail_]
:    Remove an ng_eiface(4) associated with the indicated _jail_. If the _interface_ matches the jail name, _jail_ may be omitted.

**create** _interface_ [_bridge_]
:    Create a new ng_eiface(4) associated with the indicated _bridge_ and add it to **rc.conf** so it will be created on startup. If only one ng_bridge(4) is present, _bridge_ may be omitted.

**destroy** _interface_
:    Remove the indicated ng_eiface(4) and remove it from **rc.conf**.

**vmconf**
:    Add the bridges configured in **rc.conf** to the vm(8) configuration, e.g., **/vm/.config/system.conf**.

**vmname**
:    Name ng_socket(4) devices associated with bhyve instances running via vm(8).

# RC.CONF VARIABLES

The following variables can be manually configured Some of the above subcommands will use sysrc(8) to configure rc.conf with the following variables for persistent configuration on service restart or system reboot, which can also be edited manually.

_ngbuddy_enable_
:    Set to _YES_ to enable the service. 

_ngbuddy\_(_BRIDGE_)\_if_
:    Link a new ng_bridge(4) device named _BRIDGE_ to the indicated interface, e.g., _eth0_. If the interface already exists, link it to the new bridge and disable LRO/TSO. If the interface does not exist, create it as an ng_eiface(4) device. This variable will be set with the **bridge** and **unbridge** subcommands.

_ngbuddy\_(_BRIDGE_)\_list_
:    A space delimited list of additional ng_eiface(4) devices that will be attached to _BRIDGE_ at startup. This variable will be set with the **create** and **destroy** subcommands.

_ngbuddy_set_mac_
:    If set to _YES_, created ng_eiface hardware addresses will be determined only from a hash of the interface name; this ensures each interface's MAC address is stable between hosts. If set to another string, such as a host or domain name, add that seed to the MAC address generator. The default behavior will used FreeBSD's default MAC address generator, which is prone to MAC address collisions in large networks.

_ngbuddy_set_mac_prefix_
:    Override the default MAC address prefix of **58:9C:FC** (the OUI of the FreeBSD Foundation). For example, you can set _ngbuddy_set_mac_prefix="02"_ to minimize the risk of collisions.

_ngbuddy_set_mac_hash_
:    Override the default hash command of **sha1** with the command indicated. The command's output will receive the seed through standard input (see _ngbuddy_set_mac_) and must return enough hexadecimal characters to complete the MAC address.

# FILES
**/usr/local/etc/rc.d/ngbuddy**
:    The Netgraph Buddy run control script.

**/usr/local/share/ngbuddy/ngbuddy-status.awk**
:    Helper for **service ngbuddy status**

**/usr/local/share/ngbuddy/ngbuddy-mmd.awk**
:    An alternative to **ngctl dot** that creates a Mermaid-JS color diagram of netgraph nodes.

# NOTES

These scripts were developed to assist with new netgraph features in **vm-bhyve 1.5+**, and were inspired by the **/usr/share/examples/jails/jng** example script and additional examples by Klara Systems.

# EXAMPLES

**Example 1: Quickly deploy a VNET jail with netgraph using jail.conf.d**

The following steps will configure a jail attached to the interface associated with your default route, likely your LAN, using DHCP. See the files in **examples** at: https://github.com/bellhyve/netgraph-buddy

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
- Edit the new configuration as above, chaning the word **my_jail** to **new_jail1** \
- Run: **service jail start new_jail1**
- And repeat as desired.

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

# SEE ALSO

jail(8), netgraph(4), ng_bridge(4), ngctl(8), ng_eiface(4), ng_socket(4), vm(8)

# HISTORY

Netgraph Buddy was originally developed as an internal tool for Bell Tower Integration's private cloud in August 2022.
