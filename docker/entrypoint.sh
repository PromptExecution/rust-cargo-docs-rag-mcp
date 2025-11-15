#!/bin/sh
set -eu

MODE="${CRATEDOCS_MODE:-http}"
ADDRESS="${CRATEDOCS_ADDRESS:-0.0.0.0:8080}"
DEBUG="${CRATEDOCS_DEBUG:-false}"

if [ "$MODE" = "http" ]; then
    if [ "$DEBUG" = "true" ]; then
        exec /usr/local/bin/cratedocs http --address "$ADDRESS" --debug "$@"
    else
        exec /usr/local/bin/cratedocs http --address "$ADDRESS" "$@"
    fi
else
    exec /usr/local/bin/cratedocs "$MODE" "$@"
fi
# If explicit args provided, run with those
if [ "$#" -gt 0 ]; then
  exec /usr/local/bin/cratedocs "$@"
fi

# default behavior: start in selected mode
case "$MODE" in
  http)
    if [ "${DEBUG}" = "true" ]; then
      exec /usr/local/bin/cratedocs http --address "$ADDRESS" --debug
    else
      exec /usr/local/bin/cratedocs http --address "$ADDRESS"
    fi
    ;;
  stdio)
    exec /usr/local/bin/cratedocs stdio
    ;;
  *)
    echo "Unknown CRATEDOCS_MODE: $MODE" >&2
    exit 2
    ;;
esac
