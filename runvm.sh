qemu-system-x86_64 -m 512 talos-amd64.iso -netdev user,id=mynet0 -device e1000,netdev=mynet0 -serial file:serial.log -display none -daemonize
echo $! > /tmp/vmpid

tail -f serial.log &
echo $! > /tmp/tailpid

sleep 60

kill $(cat /tmp/vmpid) $(cat /tmp/tailpid)
