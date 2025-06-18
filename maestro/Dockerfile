# syntax=docker/dockerfile:1.3
ARG BUILD_FROM
FROM swift:5.7 AS build

WORKDIR /usr/src/app
COPY swift/ ./
RUN swift build -c release --swift-sdk aarch64-swift-linux-musl

FROM ${BUILD_FROM}

COPY rootfs/ /
COPY --from=build /usr/src/app/.build/release/maestro /usr/bin/maestro

ENTRYPOINT ["/init"]
