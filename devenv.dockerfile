FROM rust:1.86-bullseye

# Install ARM cross-compilation toolchain
RUN apt-get update && apt-get install -y \
    gcc-arm-linux-gnueabihf \
    g++-arm-linux-gnueabihf \
    libc6-dev-armhf-cross \
    && rm -rf /var/lib/apt/lists/*

# Add ARM targets for Rust
RUN rustup target add armv7-unknown-linux-musleabihf
RUN rustup target add armv7-unknown-linux-gnueabihf

# Configure Cargo to use the ARM linker
ENV CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_LINKER=arm-linux-gnueabihf-gcc
ENV CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_LINKER=arm-linux-gnueabihf-gcc
ENV CC_armv7_unknown_linux_musleabihf=arm-linux-gnueabihf-gcc
ENV CXX_armv7_unknown_linux_musleabihf=arm-linux-gnueabihf-g++
ENV CC_armv7_unknown_linux_gnueabihf=arm-linux-gnueabihf-gcc
ENV CXX_armv7_unknown_linux_gnueabihf=arm-linux-gnueabihf-g++
