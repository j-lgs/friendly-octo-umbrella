#!/bin/sh
# kill parent processes
cleanup() {
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

unshare --user --map-root-user --net --mount sh -c 'sleep 1800' &
pid="$!"
./slirp4netns --configure --mtu=65520 "$pid" tap0 > /dev/null 2>&1 &
slirppid="$!"
nsenter --wd="$(pwd)" -t "$pid" -U -m -n --preserve runvm.sh
sh -c 'qemu-system-x86_64 -m 512 talos-amd64.iso -netdev user,id=mynet0 -device e1000,netdev=mynet0 --serial mon:stdio'

kill "$pid"
kill "$slirppid"
