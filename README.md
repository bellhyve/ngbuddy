% ng-buddy(8) | System Manager's Manual
% Daniel J. Bell
% July 8, 2024

# NAME

**ng-buddy** - simplified netgraph(4) manager for jail(8) and bhyve(8)

# SYNOPSIS

**service ng-buddy enable** \
**service ng-buddy start** \
**service ng-buddy stop** \
**service ng-buddy restart** \
**service ng-buddy status**

**service ng-buddy bridge** _bridge_ _interface_ \
**service ng-buddy unbridge** _bridge

**service ng-buddy jail** _interface_ [_bridge_]\
**service ng-buddy unjail** _interface_ [_jail_]\
**service ng-buddy create** _interface_ [_bridge_]\
**service ng-buddy destroy** _interface_

**service ng-buddy vmconf** \
**service ng-buddy vmname**

# DESCRIPTION

**ng-buddy** ("Netgraph Buddy") is an rc.d script for managing netgraph(4) networks in mixed vm and jail environments. **rc.conf** variables prefixed by **ngb_** are used to manage "permanent" ng_bridge(4) and ng_eiface(4) devices.  Additional tools assist with configuring vm-bhyve and naming their sockets for statistics and graphing.

# QUICK START EXAMPLE

The following commands will configure a system for netgraph in a way that is suitable for most common setups on systems where no netgraph configuration currently exists.

**service ng-buddy enable**
:    Set **rc.conf** variables and create a _public_ bridge interface associated with the host system's default route, then create a _private_ bridge linked to a virtual interface named **nghost0** suitable for a local or NAT interfaces. It will append three **rc.conf** lines similar to the following, which you can modify before starting the service:


```sh
	ngb_enable="YES"
	ngb_public_if="em0"
	ngb_private_if="nghost0"
```

**service ng-buddy start**
:    This command creates the above interfaces.

**service ng-buddy vmconf**
:    Add the our "public" and "private" bridges to the `vm(8)` configuration.

If you'd like to use host-only or NAT interface, you must configure the newly created **nghost0** interface. For example, you may want to set up IP addresses, a DNS resolver, and a DHCP server.

Once post-configuration is to your liking, create jails or bhyve instances attached to your _public_ or _private_ bridges as you prefer. See the **jail_skel.conf** for assistance configuring jails.

# SUBCOMMANDS
Subcommands are called using **service ng-buddy _SUBCOMMAND_**. Note that all commands rely on **ngctl(8)** and require root permissions.

**enable**
:    Create a basic default **ng-buddy** configuration and enable the service.

**start**
:    Load the **ng_bridge(4)** and **ng_eiface(4)** options present in **rc.conf**.

**stop**
:    Destroy all **ng_bridge(4)** and **ng_eiface(4)** devices, regardless of whether they were created with **ng-buddy** or not.

**restart**
:    Stop, then start.

**status**
:    Print a list of **ng_bridge(4)**, **ng_eiface(4)**, and **ng_socket(4)** devices and basic usage statistics.

**service ng-buddy bridge** _bridge_ _interface_
:    Create a bridge and an associated **rc.conf** entry. If the _interface_ exists, _bridge_ will be associated with it. Otherwise, _interface_ will be created as a new **ng_eiface(4)** device.

**service ng-buddy unbridge** _bridge_
:    Remove the indicated bridge from netgraph and **rc.conf**. This operation will fail if devices appear to be attached to it.

**service ng-buddy jail** _interface_ [_bridge_] 
:    Create a new **ng_eiface(4)** associated with the indicated _bridge_.

**service ng-buddy unjail** _interface_ [_jail_]
:    Remove an **ng_eiface(4)** associated with the indicated _jail_.

**service ng-buddy create** _interface_ [_bridge_]
:    Create a new **ng_eiface(4)** associated with the indicated _bridge_ and add it to **rc.conf** so it will be created on startup.

**service ng-buddy destroy** _interface_
:    Remove an **ng_eiface(4)** associated with the indicated _jail_ and remove it from **rc.conf**.

**service ng-buddy vmconf**
:    Add the bridges in **rc.conf** to the **vm(8)** configuration.

**service ng-buddy vmname**
:    Name **ng_socket(4)** devices associated with bhyve instances running via **vm(8)**.

# RC.CONF VARIABLES

The above subcommands will use sysrc(8) to configure rc.conf with the following variables for persistent configuration on service restart or system reboot, which can also be edited manually.

**ngb_enable=YES**
:    Enable the service.

**ngb_BRIDGE_if="IF"**
:    Link a new BRIDGE to interface IF. If IF does not exist, create an ng_eiface device.

**ngb_BRIDGE_list="IF1 IF2 ...**
:    Create additional ng_eiface devices attached to BRIDGE.

**ngb_set_mac="** _YES_ | _SEED_ **"**
:    If YES, the assigned hardware address will be determined from the interface name. To prevent collisions with other Netgraph Buddy hosts on a physical interface bridge, choose a unique seed such as `${hostname}`.


# FILES
**/usr/local/etc/rc.d/ng-buddy**
:    The Netgraph Buddy run control script.

**/usr/local/share/ng-buddy/**
:    Helper scripts for the **status** and **mermaid** subcommands.

# NOTES

These scripts were developed to assist with new netgraph features in **vm-bhyve 1.5+**, and were inspired by the **/usr/share/examples/jails/jng** example script and additional examples by Klara Systems.

# SEE ALSO

netgraph(4), ng_bridge(4), ngctl(8), ng_eiface(4), ng_socket(4), vm(8)

# HISTORY

Netgraph Buddy (as "ngup") was originally developed as an internal tool for Bell Tower Integration in August 2022.

# CONTRIBUTING

To submit bug reports or contribute, see https://github.com/bellhyve/netgraph-buddy.
