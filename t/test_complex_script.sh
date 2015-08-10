#!/bin/bash

set -euo pipefail

export PATH=$PATH:$(readlink -m "$BASH_SOURCE/../../bin")

script=$(mktemp)
trap "rm -f $script" EXIT

cat $(which bashpp) >$script
bash ${bash_opts:-} bashpp $script >$script.a
diff $script $script.a
