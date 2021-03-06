#!/bin/sh
# kill parent processes
cleanup() {
    kill $(cat ./qemu-1.pid)
    kill $(cat ./qemu-2.pid)
    kill $(cat ./qemu-3.pid)
    kill $(cat ./qemu-4.pid)
    pkill -P $$
}

# Setup signals to kill child processes on exit.
for sig in INT QUIT HUP TERM; do
  trap "
    cleanup
    trap - $sig EXIT
    kill -s $sig "'"$$"' "$sig"
done
trap cleanup EXIT

timeout="120"

ip link add br0 type bridge
ip link set dev tap9 master br0
ip link set dev br0 up

ip address delete 10.0.2.100/24 dev tap9
ip address add 10.0.2.100/24 dev br0
ip route add default via 10.0.2.2 dev br0

ip tuntap add dev tap0 mode tap
ip link set dev tap0 master br0
ip link set tap0 up

ip tuntap add dev tap1 mode tap
ip link set dev tap1 master br0
ip link set tap1 up

ip tuntap add dev tap2 mode tap
ip link set dev tap2 master br0
ip link set tap2 up

ip tuntap add dev tap3 mode tap
ip link set dev tap3 master br0
ip link set tap3 up

rm *.log

RAND_MAC_1="de:ad:be:ef:54:be"
RAND_MAC_2="de:ad:be:ef:ec:72"
RAND_MAC_3="de:ad:be:ef:88:c0"
RAND_MAC_4="de:ad:be:ef:41:1c"

qemu-system-x86_64 -m 1024 -cdrom talos-amd64.iso -netdev tap,id=mynet0,ifname=tap0,script=no,downscript=no -device virtio-net-pci,netdev=mynet0,mac=$RAND_MAC_1 -serial file:serial-1.log -display none -daemonize -pidfile ./qemu-1.pid --enable-kvm

qemu-system-x86_64 -m 1024 -cdrom talos-amd64.iso -netdev tap,id=mynet0,ifname=tap1,script=no,downscript=no -device virtio-net-pci,netdev=mynet0,mac=$RAND_MAC_2 -serial file:serial-2.log -display none -daemonize -pidfile ./qemu-2.pid --enable-kvm

qemu-system-x86_64 -m 1024 -cdrom talos-amd64.iso -netdev tap,id=mynet0,ifname=tap2,script=no,downscript=no -device virtio-net-pci,netdev=mynet0,mac=$RAND_MAC_3 -serial file:serial-3.log -display none -daemonize -pidfile ./qemu-3.pid --enable-kvm

qemu-system-x86_64 -m 1024 -cdrom talos-amd64.iso -netdev tap,id=mynet0,ifname=tap3,script=no,downscript=no -device virtio-net-pci,netdev=mynet0,mac=$RAND_MAC_4 -serial file:serial-4.log -display none -daemonize -pidfile ./qemu-4.pid --enable-kvm

tail -f serial-1.log &

sleep "$timeout"

ping -c 5 10.0.2.15
ping -c 5 10.0.2.16
ping -c 5 10.0.2.17
ping -c 5 10.0.2.18

cat serial-3.log
