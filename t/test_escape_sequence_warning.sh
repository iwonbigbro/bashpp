#!/bin/bash

set -euo pipefail

export PATH=$PATH:$(readlink -m "$BASH_SOURCE/../../bin")

script=$(mktemp)
trap "rm -f $script" EXIT

VERBOSE=0

cat >$script <<'SCRIPT'
#!/bin/bash

# Copyright (C) 2015 Craig Phillips.  All rights reserved.

myprogram=$(readlink -f "$BASH_SOURCE")

echo "an invalid escape sequence"

exit 0
SCRIPT

cat >$script.e <<EXPECTED
$script:7:8 warning: unexpected character in escape sequence
  echo "^[an invalid escape sequence"  
  ........^
EXPECTED

bash ${bash_opts:-} bashpp $script 1>/dev/null 2>$script.a </dev/null
diff -U3 $script.e $script.a
