ARG BUILD_FROM
FROM swift:5.7 as build
WORKDIR /usr/src/app
COPY swift/ ./
RUN swift build -c release --static-swift-stdlib

FROM $BUILD_FROM
COPY rootfs /
COPY --from=build /usr/src/app/.build/release/maestro /usr/bin/maestro
ENTRYPOINT ["/init"]
