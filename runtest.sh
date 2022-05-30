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

touch serial-1.log && chown 1000:1000 serial-1.log
touch serial-2.log && chown 1000:1000 serial-2.log
touch serial-3.log && chown 1000:1000 serial-3.log
touch serial-4.log && chown 1000:1000 serial-4.log

unshare --user --map-root-user --net --mount sh -c 'sleep 360' &
pid=$!
sleep 0.1
./slirp4netns --configure --mtu=65520 --disable-host-loopback $pid tap9 > /dev/null &
nsenter -U --wd="$(pwd)" -t $pid -m -n --preserve ./runvm.sh
