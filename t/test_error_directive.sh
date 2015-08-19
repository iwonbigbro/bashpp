#!/bin/bash

set -euo pipefail

export PATH=$PATH:$(readlink -m "$BASH_SOURCE/../../bin")

script=$(mktemp)
trap "rm -f $script" EXIT

VERBOSE=0

cat >$script <<'SCRIPT'
#error "I am an error"
SCRIPT

:>$script.e

cat >$script.err_e <<EXPECTED
$script:1:23 error: I am an error
EXPECTED

bash ${bash_opts:-} bashpp $script >$script.a 2>$script.err_a || true
diff -U3 $script.err_e $script.err_a
diff -U3 $script.e $script.a
