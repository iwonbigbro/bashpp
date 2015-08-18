#!/bin/bash

set -euo pipefail

export PATH=$PATH:$(readlink -m "$BASH_SOURCE/../../bin")

script=$(mktemp)
trap "rm -f $script" EXIT

VERBOSE=0

cat >$script <<'SCRIPT'
#ifndef A
echo "A is not defined"
#else
echo "A is defined"
#endif
SCRIPT

cat >$script.e1 <<'EXPECTED'
echo "A is not defined"
EXPECTED

cat >$script.e2 <<'EXPECTED'
echo "A is defined"
EXPECTED

:>$script.err_e

bash ${bash_opts:-} bashpp $script -o $script.a 2>$script.err_a || true
diff -U3 $script.err_e $script.err_a
diff -U3 $script.e1 $script.a

bash ${bash_opts:-} bashpp $script -DA -o $script.a 2>$script.err_a || true
diff -U3 $script.err_e $script.err_a
diff -U3 $script.e2 $script.a
