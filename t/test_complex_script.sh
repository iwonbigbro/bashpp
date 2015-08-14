#!/bin/bash

set -euo pipefail

export PATH=$PATH:$(readlink -m "$BASH_SOURCE/../../bin")

if [[ ${QUICK_TESTS:-1} == 1 ]] ; then
    # Skip this long running test.
    exit 80
fi

script=$(mktemp)
trap "rm -f $script" EXIT

cat $(which bashpp) >$script
bash ${bash_opts:-} bashpp $script >$script.a
diff $script $script.a
