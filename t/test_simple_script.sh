#!/bin/bash

set -euo pipefail

export PATH=$PATH:$(readlink -m "$BASH_SOURCE/../../bin")

script=$(mktemp)
trap "rm -f $script" EXIT

cat >$script <<'SCRIPT'
#!/bin/bash

# Copyright (C) 2015 Craig Phillips.  All rights reserved.

myprogram=$(readlink -f "$BASH_SOURCE")

exit 0
SCRIPT

bashpp $script >$script.a
diff -U3 $script $script.a
