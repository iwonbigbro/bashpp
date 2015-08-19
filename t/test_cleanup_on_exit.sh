#!/bin/bash

set -euo pipefail

export PATH=$PATH:$(readlink -m "$BASH_SOURCE/../../bin")

eval "$USE_ASSERT"

VERBOSE=0

script=$(mktemp)
trap "rm -f $script" EXIT

cat >$script <<'SCRIPT'
#error "Force cleanup due to bad exit"
SCRIPT

bash ${bash_opts:-} bashpp $script -o $script.a || true
[[ ! -f $script.a ]] || assert

bash ${bash_opts:-} bashpp $script >$script.a || true
[[ -f $script.a ]] || assert
