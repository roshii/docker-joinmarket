#!/bin/sh
set -e

chown -R joinmarket /jm
exec gosu joinmarket "$@"
