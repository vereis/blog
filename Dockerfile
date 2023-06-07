ARG ELIXIR_VERSION=1.17.2
ARG OTP_VERSION=27.0.1
ARG DEBIAN_VERSION=bullseye-20240701-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-bullseye-20240701-slim"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} AS builder

# We set APP_NAME - the name of your application/release (required)
ARG APP_NAME=blog

# The following are build arguments used to change variable parts of the image.
# The version of the application we are building (required)
ARG APP_VSN=1.0.0

# The environment to build with
ARG MIX_ENV=prod

ENV APP_VSN=${APP_VSN} \
    MIX_ENV=${MIX_ENV}

# install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /opt/app

# This copies our app source code into the build container
COPY . .

RUN mix local.hex --force && \
    mix local.rebar --force

RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile

WORKDIR /opt/app/apps/blog_web

RUN mix assets.deploy

WORKDIR /opt/app
RUN mix compile

RUN mix release

# From this line onwards, we're in a new image, which will be the image used in deployment
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales \
  libpng-dev libjpeg-dev libtiff-dev imagemagick pdftk-java \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ENV REPLACE_OS_VARS=true
ENV PORT=4000
ENV DB=4000

ENV DATABASE_PATH="./blog.db"
ENV SECRET_KEY_BASE="rTpAPJVKdBlNC5XxpJRNOPSX7F9900z50riy1JCY0BVkvSEyzJlOwpco8m2ieorn"
ENV BLOG_HOST="localhost"
ENV BLOG_PORT="4000"


WORKDIR /opt/app
RUN chown -R nobody /opt/app

RUN mkdir blog
RUN mkdir blog_web

COPY --chown=nobody:nobody --from=builder /opt/app/_build/prod/rel/blog ./blog
COPY --chown=nobody:nobody --from=builder /opt/app/_build/prod/rel/blog ./blog_web

USER nobody

EXPOSE 8080

CMD /opt/app/blog_web/bin/blog start
