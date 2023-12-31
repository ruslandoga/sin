FROM hexpm/elixir:1.15.4-erlang-26.0.2-alpine-3.18.2 as build

# install build dependencies
RUN apk add --no-cache --update git build-base nodejs npm

ARG GIT_SHA
ENV GIT_SHA=${GIT_SHA}

# prepare build dir
RUN mkdir /app
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# set build ENV
ENV MIX_ENV=prod

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

# build project
COPY priv priv
COPY lib lib
RUN mix compile
COPY config/runtime.exs config/

# build assets
COPY assets assets
RUN mix assets.deploy

# build release
RUN mix release

# prepare release image
FROM alpine:3.18.3 AS app
RUN apk add --no-cache --update openssl libstdc++ ncurses

WORKDIR /app

RUN chown nobody:nobody /app
USER nobody:nobody

COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/sin ./

ENV HOME=/app

CMD /app/bin/sin start
