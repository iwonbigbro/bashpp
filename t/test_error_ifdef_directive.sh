#!/bin/bash

set -euo pipefail

export PATH=$PATH:$(readlink -m "$BASH_SOURCE/../../bin")

script=$(mktemp)
trap "rm -f $script" EXIT

VERBOSE=0

cat >$script <<'SCRIPT'
#ifdef A
#error "A error"
#else
#error "B error"
#endif
SCRIPT

:>$script.e

cat >$script.err_e1 <<EXPECTED
$script:2:17 error: A error
EXPECTED

cat >$script.err_e2 <<EXPECTED
$script:4:17 error: B error
EXPECTED

bash ${bash_opts:-} bashpp $script -DA -o $script.a 2>$script.err_a || true
diff -U3 $script.err_e1 $script.err_a
diff -U3 $script.e $script.a

bash ${bash_opts:-} bashpp $script -o $script.a 2>$script.err_a || true
diff -U3 $script.err_e2 $script.err_a
diff -U3 $script.e $script.a
