ARG BUILDER_IMAGE="hexpm/elixir:1.17.3-erlang-27.1.2-debian-bookworm-20241016-slim"
ARG RUNNER_IMAGE="debian:bookworm-20241016-slim"

FROM ${BUILDER_IMAGE} AS builder

ARG MIX_ENV=prod
ENV MIX_ENV=${MIX_ENV}

# Install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Install mix dependencies
COPY mix.exs mix.lock ./
COPY apps/blog/mix.exs apps/blog/mix.exs
COPY apps/blog_web/mix.exs apps/blog_web/mix.exs
COPY config config

# Copy ecto_litefs as local dependency
COPY ecto_litefs ecto_litefs

RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile

# Copy all source code (blog before blog_web for dependencies)
COPY apps/blog/lib apps/blog/lib
COPY apps/blog/priv apps/blog/priv
COPY apps/blog_web/lib apps/blog_web/lib
COPY apps/blog_web/priv apps/blog_web/priv
COPY apps/blog_web/assets apps/blog_web/assets
COPY rel rel

# Compile the blog app first
RUN mix compile

# Build assets
WORKDIR /app/apps/blog_web
RUN mix assets.deploy
WORKDIR /app

# Build release
RUN mix release blog_web

# Runtime image
FROM ${RUNNER_IMAGE}

# Install runtime dependencies including LiteFS requirements
RUN apt-get update -y && apt-get install -y \
    libstdc++6 openssl libncurses5 locales ca-certificates \
    libvips42 fuse3 sqlite3 \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Copy LiteFS binary
COPY --from=flyio/litefs:0.5 /usr/local/bin/litefs /usr/local/bin/litefs

# Set locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

WORKDIR /app

# Copy release
COPY --from=builder /app/_build/prod/rel/blog_web ./

# Copy LiteFS config
COPY litefs.yml /etc/litefs.yml

# LiteFS needs to run as root for FUSE
# Application runs as nobody via su in litefs.yml exec

# Fly.io IPv6 settings
ENV ECTO_IPV6=true
ENV ERL_AFLAGS="-proto_dist inet6_tcp"

# LiteFS as entrypoint (supervisor mode)
ENTRYPOINT litefs mount
