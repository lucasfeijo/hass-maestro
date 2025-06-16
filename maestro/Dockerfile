# syntax=docker/dockerfile:1.3
ARG BUILD_FROM
ARG TARGETARCH

FROM ${BUILD_FROM} AS build

# Install essentials (and glibc shim only on aarch64)
RUN apk add --no-cache curl bash \
    && if [ "${TARGETARCH}" = "arm64" ]; then apk add --no-cache libc6-compat; fi \
    && curl -O https://download.swift.org/swiftly/linux/swiftly-$(uname -m).tar.gz \
    && tar zxf swiftly-$(uname -m).tar.gz \
    && ./swiftly init --quiet-shell-followup \
    && . "${SWIFTLY_HOME_DIR:-$HOME/.local/share/swiftly}/env.sh" \
    && hash -r \
    && swiftly install 5.7

WORKDIR /usr/src/app
COPY swift/ ./
RUN . "${SWIFTLY_HOME_DIR:-$HOME/.local/share/swiftly}/env.sh" \
    && swift build -c release --static-swift-stdlib

FROM ${BUILD_FROM}

# Only add glibc shim on aarch64 for runtime
ARG TARGETARCH
RUN if [ "${TARGETARCH}" = "arm64" ]; then apk add --no-cache libc6-compat; fi

COPY rootfs/ /
COPY --from=build /usr/src/app/.build/release/maestro /usr/bin/maestro

ENTRYPOINT ["/init"]