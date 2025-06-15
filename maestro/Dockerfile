ARG BUILD_FROM
ARG TARGETPLATFORM

FROM --platform=$TARGETPLATFORM swift:6.1-focal AS build
WORKDIR /usr/src/app
COPY swift/ ./
RUN swift build -c release --static-swift-stdlib

FROM ${BUILD_FROM}
RUN apk add --no-cache libc6-compat gcompat libstdc++ zlib
COPY rootfs/ /
COPY --from=build /usr/src/app/.build/release/maestro /usr/bin/maestro
RUN chmod +x /usr/bin/maestro
ENTRYPOINT ["/init"]