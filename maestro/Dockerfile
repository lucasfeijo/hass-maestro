# syntax=docker/dockerfile:1.3
ARG BUILD_FROM
FROM swift:6.1.2 AS build

# Install Static Linux SDK
RUN swift sdk install https://download.swift.org/swift-6.1.2-release/static-sdk/swift-6.1.2-RELEASE/swift-6.1.2-RELEASE_static-linux-0.0.1.artifactbundle.tar.gz --checksum df0b40b9b582598e7e3d70c82ab503fd6fbfdff71fd17e7f1ab37115a0665b3b

WORKDIR /usr/src/app
COPY swift/ ./
RUN swift build -c release --swift-sdk aarch64-swift-linux-musl \
    && ls -al /usr/src/app/.build/release

FROM ${BUILD_FROM}

COPY rootfs/ /
COPY --from=build /usr/src/app/.build/release/maestro /usr/bin/maestro
RUN ls -al /usr/bin/maestro

ENTRYPOINT ["/init"]
