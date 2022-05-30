#!/bin/sh
# kill parent processes
cleanup() {
    kill $(cat ./qemu.pid)
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

timeout="30"

ip link add br0 type bridge
ip tuntap add dev tap0 mode tap
ip link set dev tap0 master br0
ip link set dev tap9 master br0
ip link set dev br0 up

ip address delete 10.0.2.100/24 dev tap9
ip address add 10.0.2.100/24 dev br0
ip route add default via 10.0.2.100 dev br0

ip link set tap0 up
ip a

qemu-system-x86_64 -m 512 -cdrom talos-amd64.iso -netdev tap,id=mynet0,ifname=tap0,script=no,downscript=no -device virtio-net-pci,netdev=mynet0 -serial file:serial.log -display none -daemonize -pidfile ./qemu.pid
tail -f serial.log &
tailpid="$!"

sleep "$timeout"
ping -c 5 10.0.2.15
ip neigh
