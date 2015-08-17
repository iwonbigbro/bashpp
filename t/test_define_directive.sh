#!/bin/bash

set -euo pipefail

export PATH=$PATH:$(readlink -m "$BASH_SOURCE/../../bin")

script=$(mktemp)
trap "rm -f $script" EXIT

cat >$script <<'SCRIPT'
#define A 1
#define B

echo A
echo B

var_A=A
var_B=B

A=A
B=B

echo $var_A
echo $var_B

echo $A
echo $B

a="A"
b="B"
SCRIPT

cat >$script.e <<'EXPECTED'

echo 1
echo 1

var_A=1
var_B=1

A=1
B=1

echo $var_A
echo $var_B

echo $A
echo $B

a="A"
b="B"
EXPECTED

bash ${bash_opts:-} bashpp $script >$script.a
diff -U3 $script.e $script.a
