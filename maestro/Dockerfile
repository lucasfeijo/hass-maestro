ARG BUILD_FROM
FROM ${BUILD_FROM} AS build

# Install glibc compatibility and essential tools
RUN apk add --no-cache libc6-compat curl bash

# Install Swiftly & Swift toolchain
RUN curl -O https://download.swift.org/swiftly/linux/swiftly-$(uname -m).tar.gz \
 && tar zxf swiftly-$(uname -m).tar.gz \
 && ./swiftly init --quiet-shell-followup \
 && . "${SWIFTLY_HOME_DIR:-$HOME/.local/share/swiftly}/env.sh" \
 && hash -r \
 && swiftly install 5.7

WORKDIR /usr/src/app
COPY swift/ ./
RUN . "${SWIFTLY_HOME_DIR:-$HOME/.local/share/swiftly}/env.sh" \
 && swift build -c release --static-swift-stdlib

FROM ${BUILD_FROM}

# Runtime glibc shim
RUN apk add --no-cache libc6-compat

COPY rootfs/ /
COPY --from=build /usr/src/app/.build/release/maestro /usr/bin/maestro

ENTRYPOINT ["/init"]