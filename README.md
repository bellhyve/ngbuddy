## Netgraph Buddy

These scripts attempt to illustrate the _minimum_ required to get a netgraph bridge & nodes working for bhyve and VNET jails in FreeBSD. Such a tool is useful especially if your hosts want to network VMs and jails together, and is especially interesting now that we have solid netgraph support in bhyve and some support in the latest vm-bhyve 1.5 release.


**Setup for a private network**
`sysrc netgraph_host_enable=YES`

**Optionally bridge to your physical network on ix0**
`sysrc netgraph_host_extif="ix0"`

**Create interface nghost0 and bridge ngbr0**
`./netgraphup`

**Optionally add additional interfaces, e.g., for jails (not needed for VMs)**
`./ngaddif one0`
`./ngaddif two0`
`./ngaddif three0`

## Working with vm-bhyve

vm-bhyve 1.5+ requiredd. Using our default bridge name (ngbr0), something like these commands will work:
`sysrc -f /vm/.config/system.conf switch_list+=ngbr0`
`sysrc -f /vm/.config/system.conf type_ngbr0=netgraph`
And then, define the switch in your VM configs as follows:
`network0_switch="ngbr0"`

## Working with jail.conf

Make an interface:
`./ngaddif jail0`

Add these lines do your jail's configuration:
`vnet.interface = "jail0";`
`exec.prestop = "ifconfig jail0 -vnet jail_name";`

## Goals

I'd like to get this script to the point that it can relatively safely build up, expand, and tear down a bridge or three with a concise bit of rc.conf and a `service ngbuddy start/stop`.

## FAQ

**Can this coexist with my if_bridge (epair/tap) setup?**
You bet. You can even `ifconfig bridge0 addm nghost0` to link your netgraph stuff to if_bridge stuff, which is handy for migration.

**The ngaddif script is dumb and I want something that helps you create & tear down jail interfaces from jail.conf.**
See `/usr/share/examples/jails/jng` for a much more robust tool for jails.

**I made an interface I don't want.**
Mind the final colon:
`ngctl shutdown loser0:`

**How do I make a PNG netgraph map?**
`ngctl dot | dot -T png -o map.png`
