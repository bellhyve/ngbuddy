# Netgraph Buddy FAQ

This FAQ is adapapted from the previous release notes. Please see `man ng-buddy` (also available in the repo as README.md) for detailed usage instructions.

## Old Notes

These scripts were developed to assist with new netgraph features in **vm-bhyve 1.5+**, and were inspired by [jng](https://github.com/freebsd/freebsd-src/blob/main/share/examples/jails/jng) and [the Netgraph article by Klara Systems](https://klarasystems.com/articles/using-netgraph-for-freebsds-bhyve-networking/).

## Further detail on ustomizing and extending ngup

The default **public** bridge binds to a real interface associated with the default route.

The default **private** bridge creates an interface called *nghost0* intended for host-only networking or NAT networking. For example, you can run a DHCP & DNS server on nghost0 for your guests, and use _pf_ or _ipfw_ to NAT out.

It is generally a good practice to keep bridge names consistent between failover hosts, and you might want bridge names that are more descriptive than the defaults. For example `cli1bridge`, `lan`, and `wan206` might be clearer bridge names than "public"/"private".

## FAQ

**Can this coexist with my if_bridge (epair/tap) setup?**

You bet; an if_bridge interface and eiface (Netgraph interface) can share a network through a bridge, including a physical or private network with DHCP. Try `ifconfig bridge0 addm nghost0` to link your "private" ngup interfaces to your if_bridge epairs/taps/etc. This is handy for an in-place virtual jail migration from epair to netgraph.

**How do I make a PNG Netgraph map of my insane ngup configuration?**

Use the graphviz package:

`ngctl dot | dot -T png -o map.png`

Also see the script in the Netgraph Buddy repo, `ng-buddy-mermaid.awk` to create a Mermaid-JS diagram that is vm-bhyve and jail name aware: https://github.com/bellhyve/netgraph-buddy/blob/dev/share/ng-buddy/ng-buddy-mermaid-js.awk

This is likely to be published in the FreeBSD port soon.


**Why does this file look like you've never used markdown before?**

¯\_(ツ)_/¯
