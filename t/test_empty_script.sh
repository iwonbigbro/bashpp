#!/bin/bash

set -euo pipefail

export PATH=$PATH:$(readlink -m "$BASH_SOURCE/../../bin")

VERBOSE=0

script=$(mktemp)
trap "rm -f $script" EXIT

:>$script
:>$script.err_e

self=${BASHPID:-$$}

( sleep 2 ; kill $self ) &

bash ${bash_opts:-} bashpp $script -o $script.a 2>$script.err_a &
bashpp_pid=$!

SECONDS=0
while kill -0 $bashpp_pid 2>/dev/null ; do
    sleep 0.1

    if (( SECONDS > 1 )) ; then
        echo "timeout error"
        kill $bashpp_pid
        exit 1
    fi
done

diff -U3 $script.err_e $script.err_a
diff -U3 $script $script.a
