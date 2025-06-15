ARG BUILD_FROM
FROM swift:5.7 as build
WORKDIR /usr/src/app
COPY swift/ ./
RUN apt-get update && apt-get install -y libfts-dev
RUN swift build -c release --static-swift-stdlib -Xlinker -static

FROM $BUILD_FROM
RUN apk add --no-cache libc6-compat libstdc++ gcompat
COPY rootfs /
COPY --from=build /usr/src/app/.build/release/maestro /usr/bin/maestro
ENTRYPOINT ["/init"]
