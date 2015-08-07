#!/bin/bash

set -euo pipefail

exec 1>/dev/null

export PATH=$PATH:$(readlink -m "$BASH_SOURCE/../../bin")

bashpp --help
