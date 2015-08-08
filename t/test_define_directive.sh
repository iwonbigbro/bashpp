#!/bin/bash

set -euo pipefail

export PATH=$PATH:$(readlink -m "$BASH_SOURCE/../../bin")

script=$(mktemp)
trap "rm -f $script" EXIT

cat >$script <<'SCRIPT'
#define A 1
#define B

A
B
SCRIPT

cat >$script.e <<'EXPECTED'



1
1
EXPECTED

bashpp $script >$script.a
diff -U3 $script.e $script.a
