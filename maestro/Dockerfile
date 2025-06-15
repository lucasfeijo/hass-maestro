ARG BUILD_FROM
FROM ${BUILD_FROM} as build

# Install Swiftly and Swift
RUN apk add --no-cache \
    wget \
    && wget -q https://swift.org/swiftly/swiftly-install.sh \
    && chmod +x swiftly-install.sh \
    && ./swiftly-install.sh \
    && rm swiftly-install.sh \
    && swiftly install 5.7

WORKDIR /usr/src/app
COPY swift/ ./
RUN swiftly run swift build -c release

FROM ${BUILD_FROM}
COPY rootfs /
COPY --from=build /usr/src/app/.build/release/maestro /usr/bin/maestro
ENTRYPOINT ["/init"]
