#!/bin/sh
#
# Starting the current env, might have to build it.
#

. ./.env

docker compose up "${CURRENT}" --wait -d
