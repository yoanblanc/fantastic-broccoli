#!/bin/sh
#
# Blue-Green starts the CURRENT yet, unused image.
# Then it tells NGINX about it and reloads it.
# And finally, after an arbitrary amount of time (because no active checks)
# stops the OLD one.
#

set -e

. ./.env

if [ "$CURRENT" = "blue" ]
then
    OLD="green"
else
    OLD="blue"
fi

# Start the CURRENT service
export CURRENT
./start.sh

# Change the NGINX current upstream in the config
echo "Performing the transition to ${CURRENT}"
sed -i "s|upstream ${OLD}|upstream ${CURRENT}|" ./nginx/nginx.conf

# Reload NGINX
docker compose kill --signal SIGHUP load-balancer

# Wait a bit
sleep 10

# Graceful stop the app
echo "Stopping the old service ${OLD}"
docker compose kill --signal SIGTERM "${OLD}"
echo ""

# Wait again (not useful as it's dead after the SIGTERM)
sleep 1

# Forcefully stop the app
docker compose kill --remove-orphans "${OLD}"
echo ""
