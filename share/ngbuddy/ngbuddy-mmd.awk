#!/usr/bin/awk -f
# Draw a Mermaid graph of bridges & instance interfaces. Developed for hosts
# using vm-bhyve 1.5, and Netgraph interface nodes. Needs ng-buddy's vmname()
# function name bhyve sockets.

# This can probably be simplified in-awk with [^patterns]
function is_member(list, item) {
	"echo "list"|grep -Eo '\\<"item"\\>'|wc -l"|getline matches
	return matches
}

function get_networks() {
	while ("netstat -nr|grep '/.*link#'"|getline) {
		gsub(/\./, "_", $4)
		network[$4] = $1
	}
}

# Using vm-bhyve to find interfaces as bhyvectl doesn't reveal this (that seems
# like a pretty bad upstream issue).
function get_vm_links() {
	get_bridges = "|awk '/virtual-switch:/{print $2}'|xargs"
        while ("pgrep -lf bhyve|cut -wf3"|getline vm) {
		"vm info "vm get_bridges|getline vm_bridge[vm]
	}
}

function get_jail_links() {
	# This will also show if_bridge and tap, but not wg
	get_ifs = " ngctl list|awk '/Type: ether/{print $2}'|xargs"
	while ("jls name"|getline jail) {
		"jexec "jail get_ifs|getline jail_ifs[jail]
	}
}

function get_ng_links() {
	# Step through the netgraph list to find bridges and decuce which links
	# are buried in vnet.
	"ifconfig -lu"|getline host_up_ifs
	"ifconfig -l"|getline host_ifs
	while ("ngctl list -l"|getline) {
		if ($3=="Type:") {
			if ($4=="bridge") {
				bridge = $2
				bridge_list[bridge]=1
				label[bridge] = "BR"++b
			} else { bridge = "" }
		} else if (bridge && sub(/link/,"",$1)) {
			peer = $2
			if (label[peer]) continue
			label[peer] = "IF"(++i)
			peer_bridge[peer] = bridge

			# TO-DO: Make this better
			if ($5=="vmlink") { bridge_vm[bridge]=peer" "bridge_vm[bridge] }
			if ($3=="ether") { ether[peer] = bridge }
			else if ($3=="eiface") {
				if (is_member(host_up_ifs,peer)) { host_eiface[peer] = bridge }
				else if (is_member(host_ifs,peer)) { down_eiface[bridge] = peer"\\n"down_eiface[bridge] }
				else { vnet_eiface[peer] = bridge } # Might miss some in jail scans.
			}
		}
	}
}


BEGIN {
	get_networks()
	get_vm_links()
	get_jail_links()
	get_ng_links()

	# Can I seriously not print a multi line constant string without "\EOL"?
	print "flowchart \n\
classDef HOST fill:#e6f2ff; \n\
classDef BRIDGE fill:#ffe6cc; \n\
classDef ETHER fill:#ffb3b3; \n\
classDef EIFACE fill:#fec5e5; \n\
classDef DOWN fill:#7f7f7f; \n\
classDef VM fill:#eeffe6; \n\
classDef JAIL fill:#f9ecf9;"
	"hostname"|getline host
	host="HOST(("host")):::HOST"

	# Merge host connections to function:
	for (peer in ether) {
		peer_net = ether[peer] (network[peer] ? ":"network[peer] : "")
		print host" -->|"peer"| "label[ether[peer]]"{"peer_net"}:::ETHER"
	}
	for (peer in host_eiface) {
		peer_net = host_eiface[peer] (network[peer] ? ":"network[peer] : "")
		print host" --o|"peer"| "label[host_eiface[peer]]"[/"peer_net"\\]:::EIFACE"
	}

	# Names reused between jails will appear miswired.
	for (jail in jail_ifs) {
		jail_label = "JAIL"++num_jails
		print jail_label"(["jail"]):::JAIL"
		$0 = jail_ifs[jail]
		for (link=1;link<=NF;link++) {
			if (label[peer_bridge[$link]]) {
				print label[peer_bridge[$link]]" ---|"$link"| "jail_label
			} else { print jail_label" ---|"$link"| IF"++i"("$link")" }
		}
	}


	# I don't see how to match netgraph names to VM names, so we'll have to
	# guess based on interface names for now.
	for (vm in vm_bridge) {
		vm_label = "VM"++num_vms
		bridge = vm_bridge[vm]
		print vm_label"(["vm"]):::VM"
		print label[bridge]" --- "vm_label"[("vm")]:::VM"
	}

	for (bridge in down_eiface) {
		#print "DOWN"++num_down"(["down_eiface[bridge]"]):::DOWN"
		print label[bridge]" --x DOWN"++num_down"(["down_eiface[bridge]"]):::DOWN"
	}
}
