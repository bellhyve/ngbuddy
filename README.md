## ngup ("Netgraph Buddy")

An rc.d script for managing netgraph networks in mixed vm+jail environments.

Features:
* Create "public" bridges, linked to a real interface.
* Create "private" bridges, linekd to a Netgraph eiface node.
* Create and destroy additional bridges and eiface nodes, e.g., for use in VNET jails.
* Configure vm-bhyve 1.5+ for use with the bridges.

This tool is inspired by [jng](https://github.com/freebsd/freebsd-src/blob/main/share/examples/jails/jng) and [the Netgraph article by Klara Systems](https://klarasystems.com/articles/using-netgraph-for-freebsds-bhyve-networking/).

By default, "service ngup enable" will generate a "public" and "private"
netgraph bridge. "public" will attach to the interface associated with the
default route, while "private" links to a new netgraph eiface called "nghost0"
for running private network services, such as dhcpd.

## Quick Start

  1. Install the script in /usr/local/etc/rc.d/ngup and make it executable.
  2. `service ngup enable`
  3. `service ngup start`
  4. `service ngup vmconf`
  5. `service ngup create pubjail public`
  6. `service ngup create privjail private`
  7. Configure your jails and vms and netgraph away!

## More Details

To clarify the above terminology, a "public" bridge connected to a host's existing interface such as the LAN, and a "private" isolated bridge adds an eiface that can be used for a host-only DHCP/DNS server with otubound NAT.

Custom bridge names can be added with *ngup_bridge_name_if* or on the fly with `service ngup bridge BRIDGE_NAME BRIDGE_IF`. If the interface exists we'll bridge to it ("public"). If the interface doesn't exist, we'll create an eiface with that name along with the bridge ("private").

These bridges can be updated or added to vm-bhyve 1.5+ using `service ngup vmconf`.

Link an eiface, e.g., for jails, using "service ngup create jail_name bridge_name". Drop an eiface using "service ngup destroy jail_name bridge_name". If "bridge_name" is omitted, create/destroy will try the "ngup_bridge_default" option ("public" in the default setup).

If your jail configurations match the jail name, interface name, directory, and starting host name, you can use jail variables to very easily create and clone them. Part of the jail configuration can look like this, with only the first line different between jails:

```
jail_pub_1 {
    host.hostname = $name;
    path ="/jail/$name";
    vnet.interface = "$name";
    exec.prestop = "ifconfig $name -vnet $name";
}
```

To configure vm-bhyve with your ngup switches, run `service ngup vmconf` and ngup will back up your configuration file and will update your vm-bhyve "switch list" with your ngup bridges.

## Restarting

**Warning:** `service ngup stop/restart` destroys all Netgraph eifaces and bridges, including ones not created with ngup!

## Further detail on ustomizing and extending ngup

The **public** bridge binds to a real interface (the first available "up" interface by default). Make another bridge binding to another interface with `ngup_bridge_name_if=real_if`, e.g., `sysrc ngup_voip_if=ix2`.

The **private** bridge creates an interface called *nghost0* intended for host-only networking or NAT networking. For example, you can run a DHCP & DNS server on nghost0 for your guests, and use _pf_ or _ipfw_ to NAT out. Make another private bridge by specifing the interface name to be created (one that does not already exist) with `ngup_bridge_name_if=eiface_name`, e.g., `sysrc ngup_devnet_if=dev0`.

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
