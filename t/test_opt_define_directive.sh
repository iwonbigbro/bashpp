#!/bin/bash

set -euo pipefail

export PATH=$PATH:$(readlink -m "$BASH_SOURCE/../../bin")

script=$(mktemp)
trap "rm -f $script" EXIT

VERBOSE=0

cat >$script <<'SCRIPT'

echo A
echo B

var_A=A
var_B=B

A=A
B=B
A;=B

echo $var_A
echo $var_B

echo $A
echo $B

a="A"
b="B"
SCRIPT

cat >$script.e <<'EXPECTED'

echo "1"
echo "1"

var_A="1"
var_B="1"

A="1"
B="1"
"1";="1"

echo $var_A
echo $var_B

echo $A
echo $B

a="A"
b="B"
EXPECTED

:>$script.err_e

bash ${bash_opts:-} bashpp '-DA="1"' '-DB="1"' $script -o $script.a 2>$script.err_a || true
diff -U3 $script.err_e $script.err_a
diff -U3 $script.e $script.a
