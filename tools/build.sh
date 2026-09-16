#!/usr/bin/env bash
set -euo pipefail

# Builds the Go tools into bin/, where the sway and niri configs run them from.
#
# Usage: tools/build.sh

here=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
cd "$here"
go build -o ../bin/search ./search
echo "built bin/search"
