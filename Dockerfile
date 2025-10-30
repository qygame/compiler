# syntax=docker/dockerfile:1.5
FROM gcc:14.3
WORKDIR /

# Dockerfile(BuildKit)内置参数
ARG TARGETPLATFORM

RUN git config --global advice.detachedHead false

# CMAKE公关参数
ENV BUILD="cmake -S . -B build -DCMAKE_CXX_STANDARD=20 -DCMAKE_RULE_MESSAGES=OFF -DCMAKE_INSTALL_MESSAGE=NEVER"

# ---- CMake ----
ARG CMAKE_VERSION=3.31.8
RUN case "$TARGETPLATFORM" in \
      "linux/amd64") CMAKE_URL="https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh" ;; \
      "linux/arm64") CMAKE_URL="https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-aarch64.sh" ;; \
      *) echo "Unsupported platform: $TARGETPLATFORM" && exit 1 ;; \
    esac && \
    wget -q "$CMAKE_URL" -O cmake.sh && \
    chmod +x cmake.sh && \
    ./cmake.sh --skip-license --prefix=/usr/local > /dev/null && \
    rm cmake.sh

# ---- Protobuf ----
RUN git clone --branch v31.1 --depth 1 https://github.com/protocolbuffers/protobuf.git /home/protobuf && cd /home/protobuf && \
    git submodule update --init --recursive && \
    $BUILD -Dprotobuf_BUILD_SHARED_LIBS=OFF -Dprotobuf_BUILD_TESTS=OFF >/dev/null && \
    cmake --build build -j$(nproc) -- -s > /dev/null && cmake --install build > /dev/null && \
    rm -rf /home/protobuf

# ---- PostgreSQL Client ----
# -- gcc自带libpq.so, 因此这里省略了libpq.so的编译 --
RUN git clone --branch 7.10.1 --depth 1 https://github.com/jtv/libpqxx.git /home/libpqxx && cd /home/libpqxx && \
    $BUILD -DBUILD_SHARED_LIBS=off -DSKIP_BUILD_TEST=on -DBUILD_DOC=off > /dev/null && \
    cmake --build build -j$(nproc) -- -s > /dev/null && cmake --install build > /dev/null && \
    rm -rf /home/libpqxx

# ---- spdlog ----
RUN git clone --branch v1.15.3 --depth 1 https://github.com/gabime/spdlog.git /home/spdlog && cd /home/spdlog && \
    $BUILD -DSPDLOG_BUILD_SHARED=OFF -DSPDLOG_BUILD_EXAMPLE=OFF > /dev/null && \
    cmake --build build -j$(nproc) -- -s > /dev/null && cmake --install build > /dev/null && \
    rm -rf /home/spdlog

# ---- hiredis ----
RUN git clone --branch v1.3.0 --depth 1 https://github.com/redis/hiredis.git /home/hiredis && cd /home/hiredis && \
    $BUILD -DBUILD_SHARED_LIBS=OFF -DDISABLE_TESTS=ON >/dev/null && \
    cmake --build build -j$(nproc) -- -s > /dev/null && cmake --install build > /dev/null && \
    rm -rf /home/hiredis

# ---- redis-plus-plus ----
RUN git clone --branch 1.3.14 --depth 1 https://github.com/sewenew/redis-plus-plus.git /home/redis-plus-plus && cd /home/redis-plus-plus && \
    $BUILD -DREDIS_PLUS_PLUS_BUILD_SHARED=OFF -DREDIS_PLUS_PLUS_BUILD_TEST=OFF >/dev/null && \
    cmake --build build -j$(nproc) -- -s > /dev/null && cmake --install build > /dev/null && \
    rm -rf /home/redis-plus-plus

# ---- asio (header only) ----
RUN git clone --branch asio-1-34-2 --depth 1 https://github.com/chriskohlhoff/asio.git /home/asio && cd /home/asio/asio && \
    cp include/asio.hpp /usr/local/include && \
    cp -r include/asio /usr/local/include && \
    rm -rf /home/asio

# ---- tomlplusplus ----
RUN git clone --branch v3.4.0 --depth 1 https://github.com/marzer/tomlplusplus.git /home/tomlplusplus && cd /home/tomlplusplus && \
    $BUILD -DBUILD_SHARED_LIBS=OFF > /dev/null && \
    cmake --build build -j$(nproc) -- -s > /dev/null && cmake --install build > /dev/null && \
    rm -rf /home/tomlplusplus

# ---- gdb ----
RUN apt update > /dev/null && apt install gdb -y > /dev/null

# ---- clangd ----
RUN apt install clangd -y > /dev/null

RUN ldconfig
