# Elixir runtime for convert_to_hex.
# Pinned to a specific Elixir/OTP/Debian combo for reproducibility.
FROM hexpm/elixir:1.18.3-erlang-27.3.4.12-debian-bookworm-20260518-slim

ENV DEBIAN_FRONTEND=noninteractive \
    MIX_ENV=prod \
    LANG=C.UTF-8

# libvips42 is the runtime dep for the `vix` NIF (image I/O + pixel access).
# build-essential + git let mix compile any deps that need a C toolchain.
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      libvips42 \
      build-essential \
      git \
    && rm -rf /var/lib/apt/lists/*

RUN mix local.hex --force && mix local.rebar --force

WORKDIR /app

# Fetch and compile deps first so they cache across source edits.
COPY mix.exs mix.lock ./
RUN mix deps.get && mix deps.compile

COPY priv ./priv
COPY lib ./lib
RUN mix compile

# Test sources and formatter config aren't needed for the runtime CLI, but
# carrying them lets `mix test` and `mix format --check-formatted` run
# inside this same image in CI.
COPY .formatter.exs ./
COPY test ./test

COPY bin/convert_to_hex /usr/local/bin/convert_to_hex
RUN chmod +x /usr/local/bin/convert_to_hex

WORKDIR /work
ENTRYPOINT ["convert_to_hex"]
