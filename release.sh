#!/bin/sh
#
# This file modifies the `.env` and trigger a build of the new image as CURRENT.
#
# It's not deployed until blue-green.sh is called.
#

set -e

VERSION=${1:-}

if [ -z "$VERSION" ]
then
    echo "Version is missing, e.g."
    echo "$0 v0.1.2"
    exit 1
fi

. ./.env

if [ "$CURRENT" = "blue" ]
then
    CURRENT=green
    sed -i "s|GREEN_VERSION=.*|GREEN_VERSION=${VERSION}|" .env
else
    CURRENT=blue
    sed -i "s|BLUE_VERSION=.*|BLUE_VERSION=${VERSION}|" .env
fi

sed -i "s|CURRENT=.*|CURRENT=${CURRENT}|" .env

echo "Docker build ${CURRENT} - Version: ${VERSION}"
docker compose build "${CURRENT}"
