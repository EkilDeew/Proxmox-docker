#!/usr/bin/env bash

set -e

#IPV4_ADDR=$(ip -4 addr show $default_dev | awk '/inet / {print $2}')
#IPV6_ADDR=$(ip -6 addr show $default_dev | awk '/inet6 / {print $2}' | head -n 1)

#echo "IPv4 -> $IPV4_ADDR - IPv6 -> $IPV6_ADDR" 

# We want to start the DHCP && DHCPv6 server only if not on a macvlan # TODO
if [[ ! -z "${BRIDGE_MODE}" ]]
then
    dnsmasq
fi

intf_number=0
interfaces=$(ip -json a | jq -r '.[] | .ifname')

INTERFACES=""
INTERFACES_NB=0

function generate_ifupdown_files() {
    up_script=/run/qemu-ifup-$2
    down_script=/run/qemu-ifdown-$2
    echo """#!/usr/bin/env bash
    
    ip link set dev \$1 up
    ip link set dev \$1 master $2
    """ > $up_script

    echo """#!/usr/bin/env bash
    
    ip link set dev \$1 nomaster
    ip link set dev \$1 down
    """ > $down_script

    chmod +x $up_script
    chmod +x $down_script

    INTERFACES+="-nic tap,id=qemu${INTERFACES_NB},script=$up_script,downscript=$down_script "
}

for intf in $interfaces; do
    if [ $intf != "lo" ]; then
        bridge=qemubr${intf_number}
        
        ip addr flush dev $intf
        ip -6 addr flush dev $intf

        ip link add ${bridge} type bridge
        ip link set dev $intf master ${bridge}

        ip link set dev $intf up
        ip link set dev ${bridge} up

        generate_ifupdown_files $intf ${bridge}
        
        intf_number=$((intf_number + 1))
        INTERFACES_NB=$((INTERFACES_NB + 1))
    fi
done

exec qemu-system-x86_64 \
    -accel kvm \
    -cpu host \
    -display none \
    -m ${MEM:=4G} \
    -smp $(nproc) \
    -chardev socket,id=monitor,path=/tmp/monitor.sock,server=on,wait=off \
    -monitor chardev:monitor \
    -serial mon:stdio \
    $INTERFACES \
    /image
