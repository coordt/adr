#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

# This converts the secrets and makes them environment vars per: https://unix.stackexchange.com/a/291518
set -a
eval "$(convert_secrets /vault/secrets/)"
set +a

if [ $# -gt 0 ]; then
    echo "Running overridden command '$@'."
    exec "$@"
else
    echo "Running healthcheck"
    ./bin/start-healthcheck

    echo "Running adr"
    exec adr
fi
