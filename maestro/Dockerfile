# syntax=docker/dockerfile:1.3
ARG BUILD_FROM
ARG TARGETARCH

FROM ${BUILD_FROM} AS build

# Install curl/bash and glibc shim only on arm64
RUN apk add --no-cache curl bash \
    && if [ "$TARGETARCH" = "aarch64" ]; then apk add --no-cache libc6-compat; fi \
    && curl -sSL https://download.swift.org/swiftly/linux/swiftly-$(uname -m).tar.gz | tar xz \
    && ./swiftly init --quiet-shell-followup \
    && . "${SWIFTLY_HOME_DIR:-$HOME/.local/share/swiftly}/env.sh" \
    && swiftly install 5.7

WORKDIR /usr/src/app
COPY swift/ ./
RUN . "${SWIFTLY_HOME_DIR:-$HOME/.local/share/swiftly}/env.sh" \
    && swift build -c release --static-swift-stdlib

FROM ${BUILD_FROM}

# Provide glibc shim at runtime only on arm64
ARG TARGETARCH
RUN if [ "$TARGETARCH" = "aarch64" ]; then apk add --no-cache libc6-compat; fi

COPY rootfs/ /
COPY --from=build /usr/src/app/.build/release/maestro /usr/bin/maestro

ENTRYPOINT ["/init"]