#!/bin/bash

set -euo pipefail

export PATH=$PATH:$(readlink -m "$BASH_SOURCE/../../bin")

VERBOSE=0

script=$(mktemp)
trap "rm -f $script" EXIT

cat >$script <<'SCRIPT'
cat >somefile <<'APOS_HEREDOC'
This is not a variable$ so should not cause
any errors when parsed by an apos heredoc
parser.  All dollar$ expansion should be
ignored and not validated.
APOS_HEREDOC
SCRIPT

cat >$script.err_e <<SCRIPT
SCRIPT

bash ${bash_opts:-} bashpp $script -o $script.a 2>$script.err_a || true
diff -U3 $script.err_e $script.err_a
diff -U3 $script $script.a
