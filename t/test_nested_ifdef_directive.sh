#!/bin/bash

set -euo pipefail

export PATH=$PATH:$(readlink -m "$BASH_SOURCE/../../bin")

script=$(mktemp)
trap "rm -f $script" EXIT

VERBOSE=0

cat >$script <<'SCRIPT'
#ifdef A
#ifdef B
echo "A and B are defined"
#else B
echo "A is defined B is not defined"
#endif B
#else A
#ifdef B
echo "A is not defined B is defined"
#else B
echo "A and B are not defined"
#endif B
#endif A
SCRIPT

cat >$script.e1 <<'EXPECTED'
echo "A and B are defined"
EXPECTED

cat >$script.e2 <<'EXPECTED'
echo "A is defined B is not defined"
EXPECTED

cat >$script.e3 <<'EXPECTED'
echo "A is not defined B is defined"
EXPECTED

cat >$script.e4 <<'EXPECTED'
echo "A and B are not defined"
EXPECTED

:>$script.err_e

bash ${bash_opts:-} bashpp $script -DA -DB -o $script.a 2>$script.err_a || true
diff -U3 $script.err_e $script.err_a
diff -U3 $script.e1 $script.a

bash ${bash_opts:-} bashpp $script -DA -o $script.a 2>$script.err_a || true
diff -U3 $script.err_e $script.err_a
diff -U3 $script.e2 $script.a

bash ${bash_opts:-} bashpp $script -DB -o $script.a 2>$script.err_a || true
diff -U3 $script.err_e $script.err_a
diff -U3 $script.e3 $script.a

bash ${bash_opts:-} bashpp $script -o $script.a 2>$script.err_a || true
diff -U3 $script.err_e $script.err_a
diff -U3 $script.e4 $script.a

