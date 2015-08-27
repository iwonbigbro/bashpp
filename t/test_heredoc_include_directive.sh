#!/bin/bash

set -euo pipefail

export PATH=$PATH:$(readlink -m "$BASH_SOURCE/../../bin")

VERBOSE=0

script=$(mktemp)
trap "rm -f $script" EXIT

cat >$script.inc <<<'Included content'

cat >$script <<SCRIPT
cat <<HEREDOC_WITH_INCLUDE
#include "$script.inc"
HEREDOC_WITH_INCLUDE
SCRIPT

cat >$script.e <<EXPECTED
cat <<HEREDOC_WITH_INCLUDE
Included content
HEREDOC_WITH_INCLUDE
EXPECTED

:>$script.err_e

bash ${bash_opts:-} bashpp $script >$script.a 2>$script.err_a || true
diff -U3 $script.err_e $script.err_a
diff -U3 $script.e $script.a
