#!/bin/bash

set -euo pipefail

export PATH=$PATH:$(readlink -m "$BASH_SOURCE/../../bin")

script=$(mktemp)
trap "rm -f $script" EXIT

VERBOSE=0

cat >$script <<'SCRIPT'
#!/bin/bash

exec 1>&2
exec 1>&20
exec 1>&200
exec 1>&200;
exec 1>&200 ;
exec 1>&200 2>&1
exec 1>&200 2>&10
exec 1>&200 2>&100
exec 1>&200 2>&100;
exec 1>&200 2>&100 ;
SCRIPT

:>$script.err_e

bash ${bash_opts:-} bashpp $script -o $script.a 2>$script.err_a || true
diff -U3 $script.err_e $script.err_a
diff -U3 $script $script.a
