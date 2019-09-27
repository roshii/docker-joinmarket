#!/bin/sh
set -e

chown -R joinmarket .
exec gosu joinmarket bash
