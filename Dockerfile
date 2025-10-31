# ---------- 第一阶段：构建编译环境 ----------
FROM gcc:14.3 AS compiler

# Dockerfile(BuildKit)内置参数
ARG TARGETPLATFORM

## 减少git提示信息
RUN git config --global advice.detachedHead false

# ---- CMake ----
ARG CMAKE_VERSION=3.31.8

RUN case "$TARGETPLATFORM" in \
      "linux/amd64") CMAKE_URL="https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh" ;; \
      "linux/arm64") CMAKE_URL="https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-aarch64.sh" ;; \
      *) echo "Unsupported platform: $TARGETPLATFORM" && exit 1 ;; \
    esac && \
    wget -q "$CMAKE_URL" -O cmake.sh
RUN chmod +x cmake.sh
RUN ./cmake.sh --skip-license --prefix=/usr/local >/dev/null

# ---- ninja ----
ARG NINJA_VERSION=v1.13.1

RUN case "$TARGETPLATFORM" in \
      "linux/amd64") NINJA_URL="https://github.com/ninja-build/ninja/releases/download/${NINJA_VERSION}/ninja-linux.zip" ;; \
      "linux/arm64") NINJA_URL="https://github.com/ninja-build/ninja/releases/download/${NINJA_VERSION}/ninja-linux-aarch64.zip" ;; \
      *) echo "Unsupported platform: $TARGETPLATFORM" && exit 1 ;; \
    esac && \
    wget -q "$NINJA_URL" -O ninja.zip
RUN unzip ninja.zip >/dev/null
RUN chmod +x ninja && mv ninja /usr/local/bin


# ---------- 第二阶段：编译第三方库 ----------

# CMAKE Command
ENV BUILD="cmake -S . -B build -G Ninja -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_CXX_STANDARD=20 -DCMAKE_RULE_MESSAGES=OFF -DCMAKE_INSTALL_MESSAGE=NEVER"

# ---- Protobuf ----
RUN git clone --branch v31.1 --depth 1 https://github.com/protocolbuffers/protobuf.git /protobuf
RUN cd /protobuf && git submodule update --init --recursive
RUN cd /protobuf && $BUILD -Dprotobuf_BUILD_SHARED_LIBS=OFF -Dprotobuf_BUILD_TESTS=OFF > /dev/null
RUN cd /protobuf && cmake --build build -j$(nproc) > /dev/null
RUN cd /protobuf && cmake --install build > /dev/null

# ---- PostgreSQL Client ----
# -- gcc自带libpq.so, 因此这里省略了libpq.so的编译 --
RUN git clone --branch 7.10.1 --depth 1 https://github.com/jtv/libpqxx.git /libpqxx
RUN cd /libpqxx && $BUILD -DBUILD_SHARED_LIBS=off -DSKIP_BUILD_TEST=on -DBUILD_DOC=off > /dev/null
RUN cd /libpqxx && cmake --build build -j$(nproc) > /dev/null
RUN cd /libpqxx && cmake --install build > /dev/null

# ---- spdlog ----
RUN git clone --branch v1.15.3 --depth 1 https://github.com/gabime/spdlog.git /spdlog
RUN cd /spdlog && $BUILD -DSPDLOG_BUILD_SHARED=OFF -DSPDLOG_BUILD_EXAMPLE=OFF > /dev/null
RUN cd /spdlog && cmake --build build -j$(nproc) > /dev/null
RUN cd /spdlog && cmake --install build > /dev/null

# ---- hiredis ----
RUN git clone --branch v1.3.0 --depth 1 https://github.com/redis/hiredis.git /hiredis
RUN cd /hiredis && $BUILD -DBUILD_SHARED_LIBS=OFF -DDISABLE_TESTS=ON > /dev/null
RUN cd /hiredis && cmake --build build -j$(nproc) > /dev/null
RUN cd /hiredis && cmake --install build > /dev/null

# ---- redis-plus-plus ----
RUN git clone --branch 1.3.14 --depth 1 https://github.com/sewenew/redis-plus-plus.git /rpp
RUN cd /rpp && $BUILD -DREDIS_PLUS_PLUS_BUILD_SHARED=OFF -DREDIS_PLUS_PLUS_BUILD_TEST=OFF > /dev/null
RUN cd /rpp && cmake --build build -j$(nproc) > /dev/null
RUN cd /rpp && cmake --install build > /dev/null

# ---- asio (header only) ----
RUN git clone --branch asio-1-34-2 --depth 1 https://github.com/chriskohlhoff/asio.git /asio
RUN cd /asio/asio && cp include/asio.hpp /usr/local/include && cp -r include/asio /usr/local/include

# ---- tomlplusplus ----
RUN git clone --branch v3.4.0 --depth 1 https://github.com/marzer/tomlplusplus.git /tomlplusplus
RUN cd /tomlplusplus && $BUILD -DBUILD_SHARED_LIBS=OFF > /dev/null
RUN cd /tomlplusplus && cmake --build build -j$(nproc) > /dev/null
RUN cd /tomlplusplus && cmake --install build > /dev/null


# ---------- 第二阶段：发布阶段 ----------
FROM gcc:14.3

# 获取上阶段的STAGE
COPY --from=compiler /usr/local/bin /usr/local/bin
COPY --from=compiler /usr/local/lib /usr/local/lib
COPY --from=compiler /usr/local/include /usr/local/include

# ---- gdb, clangd ----
RUN apt update >/dev/null && apt install -y gdb clangd >/dev/null && ldconfig
