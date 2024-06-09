% ng-buddy(8) | System Manager's Manual

# NAME

**ng-buddy** - simplified netgraph(4) manager for jail(8) and bhyve(8)

# SYNOPSIS

**service ng-buddy enable** \
**service ng-buddy start** \
**service ng-buddy stop** \
**service ng-buddy restart** \
**service ng-buddy status**

**service ng-buddy bridge** _interface_ \
**service ng-buddy unbridge** _interface_

**service ng-buddy jail** _interface_ [_bridge_]\
**service ng-buddy unjail** _interface_ [_jail_]\
**service ng-buddy create** _interface_ [_bridge_]\
**service ng-buddy destroy** _interface_

**service ng-buddy vmconf** \
**service ng-buddy vmname**

# DESCRIPTION

**ng-buddy** ("Netgraph Buddy") is an rc.d script for managing netgraph(4) networks in mixed vm and jail environments. `rc.conf` variables prefixed by `ngb_` are used to manage "permanent" `ng_bridge(4)` and `ng_eiface(4)` devices.  Additional tools assist with configuring `vm(8)` (vm-bhyve) and naming their sockets for statistics and graphing.

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

**enable**  Create a basic default **ng-buddy** configuraiton and enable the service.

**start**  Load the **ng_bridge(4)** and **ng_eiface(4)** options present in **rc.conf**.

**stop**  Destroy all **ng_bridge(4)** and **ng_eiface(4)** devices, regardless of whether they were created with **ng-buddy** or not.

**restart**  Stop, then start.

**status**  Print a list of **ng_bridge(4)**, **ng_eiface(4)**, and **ng_socket(4)** devices and basic usage statistics.

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

# NOTES

These scripts were developed to assist with new netgraph features in **vm-bhyve 1.5+**, and were inspired by [jng](https://github.com/freebsd/freebsd-src/blob/main/share/examples/jails/jng) and [the Netgraph article by Klara Systems](https://klarasystems.com/articles/using-netgraph-for-freebsds-bhyve-networking/).

## Further detail on ustomizing and extending ngup

The **public** bridge binds to a real interface (the first available "up" interface by default). Make another bridge binding to another interface with `ngb_bridge_name_if=real_if`, e.g., `sysrc ngb_voip_if=ix2`.

The **private** bridge creates an interface called *nghost0* intended for host-only networking or NAT networking. For example, you can run a DHCP & DNS server on nghost0 for your guests, and use _pf_ or _ipfw_ to NAT out. Make another private bridge by specifing the interface name to be created (one that does not already exist) with `ngb_bridge_name_if=eiface_name`, e.g., `sysrc ngb_devnet_if=dev0`.

To add additional eifaces to the bridge, e.g., for use with jails, use `service ngup create`:

`service ngup create jail_inside private`

`service ngup create jail_outside public`

To add additional bridges on the fly, you can use the following, the last parameter should be the (real) ether instance to link to or associated eiface to create:

`service ngup bridge new_priv eth0`

`service ngup bridge new_pub nghost1`

Drope nodes with no associated lists with:

`service ngup destroy jail_inside`

`service ngup destroy jail_outside`

`service ngup destroy new_priv`

`service ngup destroy new_pub`


## FAQ

**Can this coexist with my if_bridge (epair/tap) setup?**

You bet; an if_bridge interface and eiface (Netgraph interface) can share a network through a bridge, including a physical or private network with DHCP. Try `ifconfig bridge0 addm nghost0` to link your "private" ngup interfaces to your if_bridge epairs/taps/etc. This is handy for an in-place virtual jail migration from epair to netgraph.


**Is there a more mature tool for jails that takes care with MAC addresses and creates & destroys nodes when starting/stopping jails?**

Check out `/usr/share/examples/jails/jng`, which is perfect for most situations and is excellent for keeping MAC addresses consistent between migrations.


**How do I make a PNG Netgraph map of my insane ngup configuration?**

Use the graphviz package:

`ngctl dot | dot -T png -o map.png`


**Why does this file look like you've never used markdown before?**

¯\_(ツ)_/¯
