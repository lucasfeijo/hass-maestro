ARG BUILD_FROM
FROM swift:5.7-slim as build
WORKDIR /usr/src/app
COPY swift/ ./
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libfts-dev \
    && rm -rf /var/lib/apt/lists/*
RUN swift build -c release --static-swift-stdlib

FROM $BUILD_FROM
RUN apk add --no-cache libc6-compat libstdc++ gcompat \
    && mkdir -p /lib64 \
    && ln -sf /lib/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2
COPY rootfs /
COPY --from=build /usr/src/app/.build/release/maestro /usr/bin/maestro
ENTRYPOINT ["/init"]
