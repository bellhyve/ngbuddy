#!/usr/bin/awk -f

function bytes(octets) {
	split("B:KB:MB:GB:TB:PB", v, ":")
	s=1
	while( octets>1024 ) {
		octets/=1024; s++
	}
	if (v[s]=="B") { return int(octets)"B" }
	return sprintf("%.2f %s",octets,v[s])
}

function getstats() {
	for (stat=3;stat<NF;stat++) {
		if (split($stat,stat_var,/=/)) {
			stats[stat_var[1]]=stat_var[2]
		}
	}
}

BEGIN {
	while ("ngctl list -l"|getline) {
		if ($3=="Type:") {
			if ($4=="bridge") {
				bridge_name = $2
				print bridge_name
			} else { bridge_name = "" }
		} else if (bridge_name && sub(/link/,"",$1)) {
			if ($5=="upper") { $2 = $2" (upper)" }
			else if ($5=="lower") { $2 = $2" (lower)" }
			link_name = $2
			statcmd = "ngctl msg "bridge_name": getstats "$1
			statcmd|getline
			statcmd|getline
			getstats()
			inbytes=bytes(stats["recvOctets"])
			outbytes=bytes(stats["xmitOctets"])
			print "  " link_name ": RX "inbytes", TX "outbytes
		}

	}
}
