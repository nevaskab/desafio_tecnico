FROM elixir:1.19.5-alpine AS build

RUN apk add --no-cache build-base git python3 npm

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
RUN mix do deps.get --only=$MIX_ENV
RUN mkdir config
COPY config/config.exs config/${MIX_ENV}.exs ./config/

RUN mix deps.compile

COPY priv priv
COPY lib lib
COPY assets assets

RUN mix compile
RUN mix assets.deploy
COPY config/runtime.exs config/
RUN mix release

FROM alpine:latest AS runtime

RUN apk add --no-cache libstdc++ ncurses-libs zlib bash openssl

WORKDIR /app

RUN mkdir -p /etc/desafio_tecnico && chown -R nobody:nobody /etc/desafio_tecnico

COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/desafio_tecnico /app

USER nobody

ENV PORT=4000 \
    PHX_SERVER=true

EXPOSE 4000

CMD ["/app/bin/desafio_tecnico", "start"]
