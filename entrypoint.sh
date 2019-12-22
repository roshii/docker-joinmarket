#!/bin/sh
set -e

chown -R $SERVICE_USER $SERVICE_DATA
exec gosu $SERVICE_USER "$@"
