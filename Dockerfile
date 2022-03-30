FROM bitwalker/alpine-elixir-phoenix:1.12

ENV GLIBC_REPO=https://github.com/sgerrand/alpine-pkg-glibc
ENV GLIBC_VERSION=2.30-r0

RUN apk --no-cache --update add alpine-sdk gmp-dev automake libtool inotify-tools autoconf python3 file && \
    set -ex && \
    apk --update add libstdc++ curl ca-certificates && \
    for pkg in glibc-${GLIBC_VERSION} glibc-bin-${GLIBC_VERSION}; \
        do curl -sSL ${GLIBC_REPO}/releases/download/${GLIBC_VERSION}/${pkg}.apk -o /tmp/${pkg}.apk; done && \
    apk add --allow-untrusted /tmp/*.apk && \
    rm -v /tmp/*.apk && \
    /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib && \
    # Get Rust
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

ENV PATH="$HOME/.cargo/bin:${PATH}"
ENV RUSTFLAGS="-C target-feature=-crt-static"

EXPOSE 4000

ENV PORT=4000 \
    MIX_ENV="prod" \
    SECRET_KEY_BASE="RMgI4C1HSkxsEjdhtGMfwAHfyT6CKWXOgzCboJflfSm4jeAlic52io05KB6mqzc5"

# download blockscout repo and compile
ARG BLOCKSCOUT_VERSION
RUN temp_dir=$(mktemp -d) && \
    cd $temp_dir && \
    git clone --depth 1 $(if [ "${BLOCKSCOUT_VERSION}" != '' ]; then echo "--branch ${BLOCKSCOUT_VERSION}"; fi) https://github.com/blockscout/blockscout.git && \
    mv blockscout/* ${HOME}/. && \
    rm -rf $temp_dir && \
    # compile
    cd ${HOME} && \
    mix do deps.get, local.rebar --force, deps.compile

ARG COIN
RUN if [ "${COIN}" != "" ]; then sed -i s/"POA"/"${COIN}"/g apps/block_scout_web/priv/gettext/en/LC_MESSAGES/default.po; fi && \
    # Run forderground build and phoenix digest
    mix compile && \
    npm install npm@latest && \
    # Add blockscout npm deps
    cd ${HOME}/apps/block_scout_web/assets/ && \
    npm install && \
    npm run deploy && \
    cd ${HOME}/apps/explorer/ && \
    npm install && \
    apk update && apk del --force-broken-world alpine-sdk gmp-dev automake libtool inotify-tools autoconf python3 && \
    cd ${HOME} && \
    mix phx.digest

# download soljson if ${SOLJSON_VERSION} passed
ARG SOLJSON_VERSION
RUN if [ "${SOLJSON_VERSION}" != '' ]; then \
    wget "https://github.com/ethereum/solidity/releases/download/v${SOLJSON_VERSION}/soljson.js" && \
    mkdir -p "${HOME}/_build/prod/lib/explorer/priv/solc_compilers" && \
    mv soljson.js "${HOME}/_build/prod/lib/explorer/priv/solc_compilers/${SOLJSON_VERSION}.js"; \
    fi

# appy patch for version v4.1.2-beta
ADD v4.1.2-beta.patch .
RUN if [ "${BLOCKSCOUT_VERSION}" == 'v4.1.2-beta' ]; then \
    git apply v4.1.2-beta.patch && \
    mix compile && \
    mix phx.digest; \
    fi
