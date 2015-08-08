#!/bin/bash

set -euo pipefail

export PATH=$PATH:$(readlink -m "$BASH_SOURCE/../../bin")

bashpp --help
