#!/bin/sh
#
# This file modifies the `.env` to the old version.
#
# It's not deployed until blue-green.sh is called.
#

set -e

. ./.env

if [ "$CURRENT" = "blue" ]
then
    CURRENT=green
    VERSION="$GREEN_VERSION"
else
    CURRENT=blue
    VERSION="$BLUE_VERSION"
fi

sed -i "s|CURRENT=.*|CURRENT=${CURRENT}|" .env

echo "Revert to ${CURRENT} - Version: ${VERSION}"
