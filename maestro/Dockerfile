# syntax=docker/dockerfile:1.3
ARG BUILD_FROM
# Use pre-built base image with Swift SDK already installed
FROM ghcr.io/lucasfeijo/swift-sdk-base:6.1.2 AS build

# SDK is already installed in the base image, no need to download again

WORKDIR /usr/src/app
COPY swift/ ./
RUN swift build -c release --swift-sdk aarch64-swift-linux-musl

FROM ${BUILD_FROM}

COPY rootfs/ /
COPY --from=build /usr/src/app/.build/release/maestro /usr/bin/maestro

ENTRYPOINT ["/init"]
