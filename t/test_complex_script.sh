#!/bin/bash

set -euo pipefail

export PATH=$PATH:$(readlink -m "$BASH_SOURCE/../../bin")

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

export TMPDIR

complex_script=$TMPDIR/complex-script.sh

cat $(which bashpp) >$complex_script

bashpp $complex_script >$complex_script.a

diff $complex_script $complex_script.a
