# syntax = docker/dockerfile:1.3-labs

FROM debian:bullseye-slim

COPY .env /tmp/

RUN <<EOF
    apt-get update
    apt-get install -y wget
    . /tmp/.env
    wget "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_Linux-64bit.deb" -O /tmp/hugo.deb
    apt-get install /tmp/hugo.deb
    apt-get clean
    rm -rf /var/lib/apt/lists/*
    rm /tmp/hugo.deb /tmp/.env
EOF

ENTRYPOINT [ "hugo" ]
