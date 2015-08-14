#!/bin/bash

set -euo pipefail

export PATH=$PATH:$(readlink -m "$BASH_SOURCE/../../bin")

VERBOSE=0

script=$(mktemp)
trap "rm -f $script" EXIT

cat >$script <<'SCRIPT'
#!/bin/bash

a=$((( 2 / 1 ) + 2 * ( 123 )))

(( ( a++ ) || b += 1 ))

a=$(mycommand $(subcommand))

if (( $(date -d"$(date +%s)" +%s) > 0 )) ; then
    true
fi
SCRIPT

cat >$script.err_e <<'OUTPUT'
OUTPUT

bash ${bash_opts:-} bashpp $script -o $script.a 2>&1 | tee $script.err_a
diff -U3 $script $script.a
diff -U3 $script.err_e $script.err_a
