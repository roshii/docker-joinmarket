#!/bin/sh
set -e

chown -R joinmarket .
cd /jm/clientserver/scripts
exec gosu joinmarket "$@"
