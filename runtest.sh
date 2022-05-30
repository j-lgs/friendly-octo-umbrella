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

unshare --net --mount sh -c 'sleep 360' &
pid="$!"
slirp4netns --configure --mtu=65520 --disable-host-loopback $pid tap9 > /dev/null 2>&1 &
nsenter --wd="$(pwd)" -t $pid -m -n --preserve ./runvm.sh
