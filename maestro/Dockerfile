ARG BUILD_FROM
FROM swift:5.7 as build
WORKDIR /usr/src/app
COPY swift/ ./
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libc6-dev \
    && rm -rf /var/lib/apt/lists/*
RUN swift build -c release --static-swift-stdlib

FROM $BUILD_FROM
RUN apk add --no-cache libc6-compat libstdc++ \
    && apk add --no-cache --repository https://dl-cdn.alpinelinux.org/alpine/edge/main \
       --repository https://dl-cdn.alpinelinux.org/alpine/edge/community \
       gcompat \
       libfts
COPY rootfs /
COPY --from=build /usr/src/app/.build/release/maestro /usr/bin/maestro
ENTRYPOINT ["/init"]
