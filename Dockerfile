ARG BUILDER_IMAGE="hexpm/elixir:1.17.3-erlang-27.1.2-debian-bookworm-20241016-slim"
ARG RUNNER_IMAGE="debian:bookworm-20241016-slim"

FROM ${BUILDER_IMAGE} AS builder

ARG MIX_ENV=prod
ENV MIX_ENV=${MIX_ENV}

RUN apt-get update -y && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

COPY mix.exs mix.lock ./
COPY apps/blog/mix.exs apps/blog/mix.exs
COPY apps/blog_web/mix.exs apps/blog_web/mix.exs
COPY config config

RUN mix deps.get --only $MIX_ENV && mix deps.compile

COPY apps/blog/lib apps/blog/lib
COPY apps/blog/priv apps/blog/priv
COPY apps/blog_web/lib apps/blog_web/lib
COPY apps/blog_web/priv apps/blog_web/priv
COPY apps/blog_web/assets apps/blog_web/assets
COPY rel rel

RUN mix compile

WORKDIR /app/apps/blog_web
RUN mix assets.deploy
WORKDIR /app

RUN mix release blog_web

FROM ${RUNNER_IMAGE}

RUN apt-get update -y && apt-get install -y \
    libstdc++6 openssl libncurses5 locales ca-certificates \
    libvips42 fuse3 sqlite3 \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

COPY --from=flyio/litefs:0.5 /usr/local/bin/litefs /usr/local/bin/litefs

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

WORKDIR /app

COPY --from=builder /app/_build/prod/rel/blog_web ./
COPY litefs.yml /etc/litefs.yml

ENV ERL_AFLAGS="-proto_dist inet6_tcp"

ENTRYPOINT litefs mount
