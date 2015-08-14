#!/bin/bash

set -euo pipefail

export PATH=$PATH:$(readlink -m "$BASH_SOURCE/../../bin")

script=$(mktemp)
trap "rm -f $script" EXIT

VERBOSE=0

exec </dev/null

cat >$script <<'SCRIPT'
#!/bin/bash

if [[ $myvar =~ ^a\ simple\ regex$ ]] ; then
    true
elif [[ $myvar =~ ^a simple\ regex$ ]] ; then
    true
fi
SCRIPT

cat >$script.err_e <<OUTPUT
$script:5:24 error: 1: unexpected characters in conditional: 'si'
  elif [[ \$myvar =~ ^a simple\\ regex\$ ]] ; then  
  .......................^
$script:5:36 error: 2: unexpected token in parameter expansion
  elif [[ \$myvar =~ ^a simple\\ regex\$ ]] ; then  
  ...................................^
OUTPUT

bash ${bash_opts:-} bashpp $script -o $script.a 2>&1 | tee $script.err_a || true
diff -U3 $script $script.a
diff -U3 $script.err_e $script.err_a
