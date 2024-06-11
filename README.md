% ngbuddy(8) | System Manager's Manual
% Daniel J. Bell
% July 8, 2024

# NAME

**ngbuddy** - simplified netgraph(4) manager for jail(8) and bhyve(8)

# SYNOPSIS

**service ngbuddy enable** \
**service ngbuddy start** \
**service ngbuddy stop** \
**service ngbuddy restart** \
**service ngbuddy status**

**service ngbuddy bridge** _bridge_ _interface_ \
**service ngbuddy unbridge** _bridge_

**service ngbuddy jail** _interface_ [_bridge_]\
**service ngbuddy unjail** _interface_ [_jail_]\
**service ngbuddy create** _interface_ [_bridge_]\
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
	ngbuddy_set_mac="NO"
```

**service ngbuddy start**
:    This command creates the above interfaces.

**service ngbuddy vmconf**
:    Add the our "public" and "private" bridges to the vm(8) configuration.

If you'd like to use host-only or NAT interface, you must configure the newly created **nghost0** interface. For example, you may want to set up IP addresses, a DNS resolver, and a DHCP server.

Once post-configuration is to your liking, create jails or bhyve instances attached to your _public_ or _private_ bridges as you prefer. See the **jail_skel.conf** for assistance configuring jails.

# SUBCOMMANDS
Subcommands are called using **service ngbuddy _SUBCOMMAND_**. Note that all commands rely on **ngctl(8)** and require root permissions.

**enable**
:    Create a basic default **ngbuddy** configuration and enable the service.

**start**
:    Load the **ng_bridge(4)** and **ng_eiface(4)** options present in **rc.conf**.

**stop**
:    Destroy all **ng_bridge(4)** and **ng_eiface(4)** devices, regardless of whether they were created with **ngbuddy** or not.

**restart**
:    Stop, then start.

**status**
:    Print a list of **ng_bridge(4)**, **ng_eiface(4)**, and **ng_socket(4)** devices and basic usage statistics.

**service ngbuddy bridge** _bridge_ _interface_
:    Create a bridge and an associated **rc.conf** entry. If the _interface_ exists, _bridge_ will be associated with it. Otherwise, _interface_ will be created as a new **ng_eiface(4)** device.

**service ngbuddy unbridge** _bridge_
:    Remove the indicated bridge from netgraph and **rc.conf**. This operation will fail if devices appear to be attached to it.

**service ngbuddy jail** _interface_ [_bridge_] 
:    Create a new **ng_eiface(4)** associated with the indicated _bridge_.

**service ngbuddy unjail** _interface_ [_jail_]
:    Remove an **ng_eiface(4)** associated with the indicated _jail_.

**service ngbuddy create** _interface_ [_bridge_]
:    Create a new **ng_eiface(4)** associated with the indicated _bridge_ and add it to **rc.conf** so it will be created on startup.

**service ngbuddy destroy** _interface_
:    Remove an **ng_eiface(4)** associated with the indicated _jail_ and remove it from **rc.conf**.

**service ngbuddy vmconf**
:    Add the bridges in **rc.conf** to the **vm(8)** configuration.

**service ngbuddy vmname**
:    Name **ng_socket(4)** devices associated with bhyve instances running via **vm(8)**.

# RC.CONF VARIABLES

The above subcommands will use sysrc(8) to configure rc.conf with the following variables for persistent configuration on service restart or system reboot, which can also be edited manually.

**ngbuddy_enable=**"_YES_"
:    Enable the service.

**ngbuddy_BRIDGE_if=**"_IF_"
:    Link a new _BRIDGE_ to interface _IF_. If _IF_ does not exist, create an ng_eiface device.

**ngbuddy_BRIDGE_list=**"_IF1 IF2 ..._"
:    Create additional ng_eiface devices attached to _BRIDGE_ at startup.

**ngbuddy_set_mac=**"_YES_|_SEED_"
:    If set to _YES_, created ng_eiface hardware addresses will be determined from the interface name; this ensures the MAC stays consistent for the named interface regardless of the host it's generated on. Instead of _YES_, you may add a seed value, such as ${hostname} or a common seed to share among jail migration partners. If _NO_, the default auto-assignment will be used, which is more prone to MAC collisions.


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

See **examples** at: https://github.com/bellhyve/netgraph-buddy

After following the above **QUICK START EXAMPLE**: \
- Append the **devfs.rules** example to **/etc/devfs.rules** \
- Extract a FreeBSD **base.txz** in **/jail/my_jail** \
- Copy the **jail_skel.conf** to **/etc/jail.conf.d/my_jail.conf** \
- In **my_jail.conf**, change the jail name to **my_jail** \
- Run: **service jail start my_jail** \

This provides a simple framework for cloning jails and editing a single template line for rapid deployment of many VNET jails.

# SEE ALSO

jail(8), netgraph(4), ng_bridge(4), ngctl(8), ng_eiface(4), ng_socket(4), vm(8)

# HISTORY

Netgraph Buddy was originally developed as an internal tool for Bell Tower Integration in August 2022.
