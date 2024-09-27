FROM debian:latest

RUN useradd -m app
RUN apt-get update && apt-get -y install \
	# for GHCup
	build-essential curl libffi-dev libgmp-dev libncurses-dev \
	# for ghc-wasm-meta
	jq unzip zstd xz-utils

USER app
WORKDIR /home/app

RUN curl -sSf https://get-ghcup.haskell.org/ | BOOTSTRAP_HASKELL_NONINTERACTIVE=1 BOOTSTRAP_HASKELL_MINIMAL=1 sh

# Randomly fail because of a network error
RUN . ~/.ghcup/env && curl -sSf https://gitlab.haskell.org/ghc/ghc-wasm-meta/-/raw/master/bootstrap.sh | sh

COPY --chown=app:app nci.hs ./
RUN . ~/.ghcup/env && . ~/.ghc-wasm/env && wasm32-wasi-ghc -Wno-x-partial -o nci.wasm nci.hs

USER root
