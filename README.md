## Netgraph Buddy

These scripts attempt to illustrate a simple netgraph bridge & nodes working for bhyve and VNET jails in FreeBSD. Such a tool is useful especially if your hosts want to network VMs and jails together, and is especially interesting now that we have solid netgraph support in bhyve and some support in the latest vm-bhyve 1.5 release.

**Enable with:**

`sysrc ngup_enable=YES`


**Create a private Netgraph bridge with the interface nghost0**

`sysrc ngup_private=YES`

(This is the default if no other option is given.)


**Create a public Netgraph bridge to your physical network**

`sysrc ngup_public=YES`


**Add some interfaces for vnet jails**

`sysrc ngup_private_list="jail1 jail2 jail3"`

`sysrc ngup_public_list="jail4 jail5"`

Note: Not needed for bhyve VMs.


**Go bananas**

`service ngup start`

You can also `service ngup restart` to clear Netgraph and start over.


**Add more Netgraph interfaces**

Add one or more interfaces in a quoted list.

`service ngup add "here are some interfaces"`


If you're using multiple bridges, add a 3rd parameter with "public" or "private:

`service ngup add jail_inside private`

`service ngup add jail_inside public`


## Defaults

You can override the following defaults.

`ngup_private_bridge="private"`

`ngup_private_if="nghost0"`

`ngup_public_bridge="public"`

`ngup_public_if="[DETECTED/GUESSED]"`


## Working with vm-bhyve

vm-bhyve 1.5+ requiredd. Using our default private bridge name ("private"), something like these commands will work:

`sysrc -f /vm/.config/system.conf switch_list+=private`

`sysrc -f /vm/.config/system.conf type_private=netgraph`

And then, define the switch in your VM configs as follows:

`network0_switch="private"`

For use with your public bridge, simply change the above names to "public," or use both.


## Working with jail.conf

Use the **ngup_private_list** and/or **ngup_public_list** variables, e.g., `sysrc ngup_public_list+=jail0`. If the jail interface name and jail name match, you can simply use the **$name** variable in your jail configuration:

`vnet.interface = "$name";`

`exec.prestop = "ifconfig $name -vnet $name";`


## FAQ

**Can this coexist with my if_bridge (epair/tap) setup?**

You bet. You can even `ifconfig bridge0 addm nghost0` to link your netgraph stuff to if_bridge stuff, which is handy for an in-place virtual jail migration.


**Is there a tool for creating/tearing down jail interfaces on the fly?**

`/usr/share/examples/jails/jng` is robust and has lots of options.


**How do I make a PNG netgraph map?**

With the graphviz package:

`ngctl dot | dot -T png -o map.png`
