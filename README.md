## Netgraph Buddy

It script creates a simple netgraph bridge & nodes working for bhyve and VNET jails in FreeBSD. Such a tool is useful especially if your hosts want to network VMs and jails together, and is especially interesting now that we have solid netgraph support in bhyve and some support in the latest vm-bhyve 1.5 release.

The **private** bridge creates an interface called *nghost0* intended for host-only networking or NAT networking. For example, you can run a DHCP server on nghost0 for your guests.

The **public** bridge binds to a real interface (the first available "up" interface by default).

**Enable the service with:** `sysrc ngup_enable=YES`


**Create a private Netgraph bridge with the interface nghost0**

`sysrc ngup_private=YES`

(This is the default if no other option is given.)


**Create a public Netgraph bridge to your physical network**

`sysrc ngup_public=YES`

Or specify an interface with: `sysrc ngup_public=ix0`


**Go bananas**

`service ngup start`

Note that `service ngup stop/restart` destroys all Netgraph links and nodes!


**Add some interfaces for vnet jails**

If you only have one bridge: `service ngup create "jail1 jail2 jail3"`

Note: You don't need these interfaces for Bhyve VMs.

Remove them with `service ngup destroy jail_if_name`


If you're using multiple bridges, add a 3rd parameter with "public" or "private:

`service ngup create jail_inside private`

`service ngup create jail_outside public`

And drop them with:

`service ngup destroy jail_inside private`

`service ngup destroy jail_outside public`


## Defaults

You can override the following defaults.

`ngup_private_bridge="private"`

`ngup_private_if="nghost0"`

`ngup_public_bridge="public"`

`ngup_public_if="[GUESSED]"`


## Working with vm-bhyve

vm-bhyve 1.5+ requiredd. Using our default private bridge name ("private"), something like these commands will work:

`sysrc -f /vm/.config/system.conf switch_list+=private`

`sysrc -f /vm/.config/system.conf type_private=netgraph`

And then, define the switch in your VM configs as follows:

`network0_switch="private"`

For use with your public bridge, simply change the above names to "public," or use both.


## Working with jail.conf

Use `service ngup create ...` or the **ngup_private_list**/**ngup_public_list** rc variables to create your jail interfaces. I recommend you set the jail interface name and jail to name match, so you can simply use the **$name** variable in your jail configuration:

`vnet.interface = "$name";`

`exec.prestop = "ifconfig $name -vnet $name";`

**TO-DO: Show full example.**


## FAQ

**Can this coexist with my if_bridge (epair/tap) setup?**

You bet. You can even `ifconfig bridge0 addm nghost0` to link your netgraph stuff to if_bridge stuff, which is handy for an in-place virtual jail migration.


**Is there a tool for creating/tearing down jail interfaces on the fly?**

`/usr/share/examples/jails/jng` is robust and has lots of options.


**How do I make a PNG Netgraph map?**

With the graphviz package:

`ngctl dot | dot -T png -o map.png`
