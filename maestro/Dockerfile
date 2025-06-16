# syntax=docker/dockerfile:1.3
ARG BUILD_FROM
# 1. Use official Swift (glibc) for *both* amd64 & arm64
FROM swift:5.7-buster AS build

WORKDIR /usr/src/app
COPY swift/ ./
RUN swift build -c release --static-swift-stdlib

# 2. Runtime on your Home-Assistant base
FROM ${BUILD_FROM}

# if your binary ever needs glibc at runtime, you can keep this;
# otherwise omit—it’s statically linked already
# RUN apk add --no-cache libc6-compat

COPY rootfs/ /
COPY --from=build /usr/src/app/.build /usr/src/app/.build

ENTRYPOINT ["/init"]