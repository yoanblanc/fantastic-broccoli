FROM golang:1.19-bullseye AS builder
ARG VERSION

WORKDIR /app
ADD . .

ARG CGO_ENABLED=0
RUN go build -ldflags "-X main.Version=${VERSION}" -o /bin/app

FROM scratch

COPY --from=builder /bin/app /

ENTRYPOINT ["/app"]
