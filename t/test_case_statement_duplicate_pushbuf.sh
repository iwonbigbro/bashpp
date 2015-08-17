#!/bin/bash

set -euo pipefail

export PATH=$PATH:$(readlink -m "$BASH_SOURCE/../../bin")

VERBOSE=0

script=$(mktemp)
trap "rm -f $script" EXIT

cat >$script <<'SCRIPT'
case $1 in
(blah*) echo "blah" ;;
(*) exit 1 ;;
esac
SCRIPT

cat >$script.err_e <<SCRIPT
SCRIPT

bash ${bash_opts:-} bashpp $script -o $script.a 2>$script.err_a
diff -U3 $script.err_e $script.err_a
diff -U3 $script $script.a
