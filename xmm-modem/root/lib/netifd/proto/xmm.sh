#!/bin/sh

. /lib/functions.sh
. /lib/functions/network.sh
. ../netifd-proto.sh
init_proto "$@"


proto_xmm_init_config() {
	no_device=1
	available=1
	proto_config_add_string "device:device"
	proto_config_add_string "apn"
	proto_config_add_string "pdp"
	proto_config_add_string "delay"
	proto_config_add_defaults
}

proto_xmm_setup() {
	local interface="$1"
	local devname devpath hwaddr ip4addr ip4mask dns1 dns2 defroute lladdr
	local name ifname proto extendprefix
	local device ifname apn pdp pincode delay $PROTO_DEFAULT_OPTIONS
	json_get_vars device ifname apn pdp pincode delay $PROTO_DEFAULT_OPTIONS
	[ "$metric" = "" ] && metric="0"
	pdp=$(echo $pdp | awk '{print toupper($0)}')
	[ "$pdp" = "IP" -o "$pdp" = "IPV6" -o "$pdp" = "IPV4V6" ] || pdp="IP" 
	[ -z $ifname ] && {
		devname=$(basename $device)
		case "$devname" in
			*ttyACM*)
				echo "Setup xmm interface $interface with port ${device}"
				devpath="$(readlink -f /sys/class/tty/$devname/device)"
				echo "Found path $devpath"
				hwaddr="$(ls -1 $devpath/../*/net/*/*address*)"
				for a in $hwaddr; do
					for h in $hwaddr; do
						if [ "$(cat ${h})" = "00:00:11:12:13:14" ]; then
							ifname=$(echo ${h} | awk -F [\/] '{print $(NF-1)}')
						fi
					done
				done
			;;
		esac
	}

	[ -n "$ifname" ] && {
		echo "Found interface $ifname"
	} || {
		echo "The interface could not be found."
		proto_notify_error "$interface" NO_IFACE
		proto_set_available "$interface" 0
		return 1
	}
	echo "Setting up $ifname"
	APN=$apn PDP=$pdp  gcom -d $device -s /etc/gcom/xmm-connect.gcom >/dev/null 2&>1
	[ -n "$delay" ] && sleep "$delay" || sleep 5
	proto_init_update "$ifname" 1
	proto_add_data
	proto_close_data
	DATA=$(gcom -d $device -s /etc/gcom/xmm-config.gcom)
	ip4addr=$(echo "$DATA" | awk -F [,] '/^\+CGPADDR/{gsub("\r|\"", ""); print $2}') >/dev/null 2&>1
	lladdr=$(echo "$DATA" | awk -F [,] '/^\+CGPADDR/{gsub("\r|\"", ""); print $3}') >/dev/null 2&>1
	ns=$(echo "$DATA" | awk -F [,] '/^\+XDNS: /{gsub("\r|\"",""); print $2" "$3}' | sed 's/^[[:space:]]//g')
	dns1=$(echo "$ns" | grep -v "0.0.0.0" | tail -1)
	if ! [ $ip4addr ]; then
		proto_notify_error "$interface" CONFIGURE_FAILED
		return 1
	fi
	
	case $ip4addr in
		*FE80*)
			lladdr=$ip4addr
			ip4addr=""
		;;
		*)
			ip4mask=24
			defroute=$(echo $ip4addr | awk -F [.] '{print $1"."$2"."$3".1"}')
		;;
	esac
	proto_set_keep 1
	ip link set dev $ifname arp off
	echo "PDP type is: $pdp"
	[ "$pdp" = "IP" -o "$pdp" = "IPV4V6" ] && {
		if ! [ "$(echo $ip4addr | grep 0.0.0.0)" ]; then
			echo "Set IPv4 address: ${ip4addr}/${ip4mask}"
			proto_add_ipv4_address $ip4addr $ip4mask
			proto_add_ipv4_route "0.0.0.0" 0 $defroute
		else
			echo "Failed to configure interface"
			proto_notify_error "$interface" CONFIGURE_FAILED
			return 1
		fi
		if ! [ "$(echo $dns1 | grep 0.0.0.0)" ]; then
			proto_add_dns_server "$dns1"
			echo "Using IPv4 DNS: $dns1"
		fi
		proto_add_data
		proto_close_data
		proto_send_update "$interface"
	
	}
	[ "$pdp" = "IPV6" -o "$pdp" = "IPV4V6" ] && {
		ip -6 address add ${lladdr}/64 dev $ifname >/dev/null 2&>1
		json_init
		json_add_string name "${interface}_6"
		json_add_string ifname "@$interface"
		json_add_string proto "dhcpv6"
		json_add_string extendprefix 1
		proto_add_dynamic_defaults
		json_close_object
		ubus call network add_dynamic "$(json_dump)"
	}
}

proto_xmm_teardown() {
	local interface="$1"
	local device
	device=$(uci -q get network.$interface.device)
	gcom -d $device -s /etc/gcom/xmm-disconnect.gcom >/dev/null 2&>1
	echo "Modem $device disconnected"
	proto_kill_command "$interface"
}

add_protocol xmm
