# Setup build image
FROM elixir:1.10.3-alpine AS builder

# Install build dependencies
RUN apk update && \
    apk add --no-cache \
    bash \
    build-base \
    curl \
    git \
    libgcc \
    python3

# Install rustup
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV RUSTUP_HOME=/root/.rustup \
    RUSTFLAGS="-C target-feature=-crt-static" \
    CARGO_HOME=/root/.cargo  \
    PATH="/root/.cargo/bin:$PATH"

# Install Node.js
RUN apk add --update npm

# Prepare app dir
WORKDIR /build
ENV HOME=/build

ARG SECRET_KEY_BASE

# Set app ENV
ENV MIX_ENV=prod
ENV SECRET_KEY_BASE=${SECRET_KEY_BASE}


# Install Hex and Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
RUN mix do deps.get, deps.compile

# Build assets
COPY assets/package.json assets/package-lock.json ./assets/
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error
COPY priv priv
COPY assets assets
RUN npm run --prefix ./assets deploy
RUN mix phx.digest

# Compile app
COPY lib lib
RUN mix compile

# Release
# COPY rel rel
RUN mix release


# Setup app image
FROM alpine AS app

RUN apk update && \
    apk add --no-cache \
    bash \
    imagemagick \
    libgcc \
    openssl-dev

RUN mkdir /app
WORKDIR /app

COPY --from=builder /build/_build/prod/rel/one_million_words ./

# COPY docker-entrypoint.sh ./
# RUN chmod +x docker-entrypoint.sh

# ENTRYPOINT ["bash", "docker-entrypoint.sh"]
CMD ["bin/one_million_words", "start"]

