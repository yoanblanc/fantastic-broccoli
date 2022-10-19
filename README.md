# Blue-Green using NGINX and Docker Compose

This is POC for a blue-green deployment, to keep things simple it's a [`docker-compose.yml`](./docker-compose.yml) file, with its `.env` that is manipulated by a bunch of shell scripts. Nothing fancy to avoid distracting us from the goal. When it comes to the down of the technology stack, boring is enjoyable.

## Structure

- [`app`](./app) - basic Go application serving one `index.html` file.
- [`nginx`](./nginx/nginx.conf) - NGINX as the load balancer.
- [`docker-compose.yml`](./docker-compose.yml) - the infra (not fancy)
- [`.env`](./.env) - the state representation
- [`start.sh`](./start.sh) - script starting the current version
- [`release.sh`](./release.sh) - script building a new release
- [`blue-green.sh`](./blue-green.sh) - script performing the Blue-Green towards the new release
- [`revert.sh`](./revert.sh) - script reverting to the old version - the opposite of `release.sh`.

In order to use it, `Docker`, `Docker Compose`, and a cool HTTP Load Generator such as [hey](https://github.com/rakyll/hey) or [oha](https://github.com/hatoo/oha).

### Demo

The current application is either `blue` or `green`. It's stored in the `.env` file.

```console
$ . .env
$ echo $CURRENT
blue
```

Let's start it

```bash
# docker compose up "$CURRENT" --wait -d
./start.sh
```

Test it.

```console
$ curl -Is http://localhost:8000/ | grep App-Version
App-Version: v0.0.1
```

`v0.0.1` comes from the `.env` file and was injected into the Application at build time.

Opening the app in the browser shows `Hello world!`, let's change this.

```bash
sed -i s/world/Lokalise/ app/public/index.html
```

In a normal world, we would create a branch, a merge/pull request, ask for reviews, and then create a new tag but it's demo, so let's move fast!

```bash
./release.sh v0.0.2
```

Then, the Blue-Green goes in three steps: start the new app, reload NGINX to redirect traffic to it, gracefull stop the old app, and finally kill the old app with cleanup.

```bash
./blue-green.sh
```

It's using a lot of `sleep` with some arbitrary values in there; where in fact the service should handle stop signal and gracefully shutdown. Without a central service registry or active checks from the router; picking up safe values is what is left.

### Stress testing

Pick some load generator like [oha](https://github.com/hatoo/oha) and run it while doing the `./blue-green.sh` step. Since everything is so fast, the service can randomly wait up to `sleep` seconds which help convince oneself that no requests where interrupted.

```console
$ oha http://localhost:8000/?sleep=10

...

Status code distributions:
  [200] 200 response
```

## Areas of improvements

At first I went with [k6](https://k6.io/) and test scripts writing into InfluxDB or Prometheus. They didn't had much value to the problem at hand: offering a POC for Blue-Green **and** showing the pitfalls in NGINX configuration or Docker Compose.

The Application is not very smart as it doesn't handle signals or healthiness/readiness endpoints, let alone metrics. In some cases, Blue-Green is used as a way to work around application not being able to do graceful shutdowns.
