#!/bin/bash

set -euo pipefail

export PATH=$PATH:$(readlink -m "$BASH_SOURCE/../../bin")

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

export TMPDIR

simple_script=$TMPDIR/simple-script.sh

cat >$simple_script <<'SCRIPT'
#!/bin/bash

# Copyright (C) 2015 Craig Phillips.  All rights reserved.

myprogram=$(readlink -f "$BASH_SOURCE")

exit 0
SCRIPT

bashpp $simple_script >$simple_script.a

diff $simple_script $simple_script.a
