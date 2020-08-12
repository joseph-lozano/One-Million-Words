FROM erlang:22-slim as rust_builder

ENV RUSTUP_HOME=/usr/local/rustup \
  CARGO_HOME=/usr/local/cargo \
  PATH=/usr/local/cargo/bin:$PATH \
  RUST_VERSION=1.41.0

RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
  ca-certificates \
  gcc \
  libc6-dev \
  wget \
  ; \
  dpkgArch="$(dpkg --print-architecture)"; \
  case "${dpkgArch##*-}" in \
  amd64) rustArch='x86_64-unknown-linux-gnu'; rustupSha256='ad1f8b5199b3b9e231472ed7aa08d2e5d1d539198a15c5b1e53c746aad81d27b' ;; \
  armhf) rustArch='armv7-unknown-linux-gnueabihf'; rustupSha256='6c6c3789dabf12171c7f500e06d21d8004b5318a5083df8b0b02c0e5ef1d017b' ;; \
  arm64) rustArch='aarch64-unknown-linux-gnu'; rustupSha256='26942c80234bac34b3c1352abbd9187d3e23b43dae3cf56a9f9c1ea8ee53076d' ;; \
  i386) rustArch='i686-unknown-linux-gnu'; rustupSha256='27ae12bc294a34e566579deba3e066245d09b8871dc021ef45fc715dced05297' ;; \
  *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
  esac; \
  url="https://static.rust-lang.org/rustup/archive/1.21.1/${rustArch}/rustup-init"; \
  wget "$url"; \
  echo "${rustupSha256} *rustup-init" | sha256sum -c -; \
  chmod +x rustup-init; \
  ./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION; \
  rm rustup-init; \
  chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
  rustup --version; \
  cargo --version; \
  rustc --version; \
  update-ca-certificates;

FROM rust_builder as elixir_builder

# elixir expects utf8.
ENV ELIXIR_VERSION="v1.10.1" \
  LANG=C.UTF-8

RUN set -xe \
  && ELIXIR_DOWNLOAD_URL="https://github.com/elixir-lang/elixir/archive/${ELIXIR_VERSION}.tar.gz" \
  && ELIXIR_DOWNLOAD_SHA256="bf10dc5cb084382384d69cc26b4f670a3eb0a97a6491182f4dcf540457f06c07" \
  && buildDeps=' \
  curl \
  make \
  ' \
  && apt-get update \
  && apt-get install -y --no-install-recommends $buildDeps \
  && curl -fSL -o elixir-src.tar.gz $ELIXIR_DOWNLOAD_URL \
  && echo "$ELIXIR_DOWNLOAD_SHA256  elixir-src.tar.gz" | sha256sum -c - \
  && mkdir -p /usr/local/src/elixir \
  && tar -xzC /usr/local/src/elixir --strip-components=1 -f elixir-src.tar.gz \
  && rm elixir-src.tar.gz \
  && cd /usr/local/src/elixir \
  && make install clean \
  && apt-get install -y git apt-transport-https ca-certificates \
  && update-ca-certificates \
  && curl -sL https://deb.nodesource.com/setup_10.x | bash - \
  && apt-get install -y nodejs;

CMD ["iex"]

FROM elixir_builder as app_builder

RUN mkdir /app
WORKDIR /app

RUN update-locale LC_ALL=en_US.UTF-8

COPY . .

ARG APP_NAME
ARG PORT
ARG SECRET_KEY_BASE
# ARG DATABASE_URL
# ARG POOL_SIZE

ENV LANG=en_US.UTF-8 \
  LANGUAGE=en_US.UTF-8 \
  LC_ALL=en_US.UTF-8 \
  MIX_ENV=prod \
  SHELL=/bin/bash \
  APP_NAME=$APP_NAME \
  PORT=$PORT \
  HOME=/app \
  SECRET_KEY_BASE=$SECRET_KEY_BASE
# DATABASE_URL=$DATABASE_URL \
# POOL_SIZE=$POOL_SIZE

ENV MIX_ENV=prod

RUN set -xe \
  && mix local.rebar --force \
  && mix local.hex --force \
  && mix do deps.get, compile \
  && npm install --prefix ./assets \
  && npm run deploy --prefix ./assets \
  && mix do phx.digest, release --overwrite

FROM debian:buster-slim


RUN mkdir /app
WORKDIR /app


# Setup locales to prevent VM from starting with latin1
# Install application runtime deps
RUN set -xe \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends openssl ca-certificates locales \
  && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
  && dpkg-reconfigure --frontend=noninteractive locales \
  && update-locale LANG=en_US.UTF-8 \
  && rm -rf /var/lib/apt/lists/*

COPY --from=app_builder /app/_build/prod/rel/${APP_NAME} .

EXPOSE ${PORT}

RUN chown -R nobody: /app
USER nobody

CMD bin/${APP_NAME} start
