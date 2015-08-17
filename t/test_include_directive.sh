#!/bin/bash

set -euo pipefail

export PATH=$PATH:$(readlink -m "$BASH_SOURCE/../../bin")

script=$(mktemp)
trap "rm -f $script" EXIT

VERBOSE=0

cat >$script.1 <<SCRIPT
# Script 1
SCRIPT

cat >$script.2 <<SCRIPT
#include <${script##*/}.1>
# Script 2
SCRIPT

cat >$script.3 <<SCRIPT
#include <${script##*/}.2>
# Script 3
SCRIPT

cat >$script.e <<EXPECTED
# Script 1
# Script 2
# Script 3
EXPECTED

bash ${bash_opts:-} bashpp -I${script%/*} $script.3 >$script.a
diff -U3 $script.e $script.a
