# ---------- 第一阶段：裁剪llvm ----------
# llvm只使用clang编译器 和 一些辅助工具(clangd, clang-format)
# ld, ar, as 使用binutils中gcc的
#
# TODO wcq 2025/10/31
# 未安装binutils的时候,
# 使用lld代替ld; llvm-ar, llvm-ranlib代替ar后, 导致有些项目报错
# clang++: error: unable to execute command: posix_spawn failed: No such file or directory
# 如果解决了所有项目的报错, 可以考虑使用llvm的lld, llvm-ar等工具代替binutils

FROM debian:12 AS llvm

# Dockerfile(BuildKit)内置参数
ARG TARGETPLATFORM

RUN apt-get update > /dev/null && \
    apt-get install -y --no-install-recommends wget ca-certificates xz-utils > /dev/null

# LLVM
ARG LLVM_VERSION=21.1.4

RUN case "$TARGETPLATFORM" in \
      "linux/amd64") LLVM_URL="https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/LLVM-${LLVM_VERSION}-Linux-X64.tar.xz" ;; \
      "linux/arm64") LLVM_URL="https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/LLVM-${LLVM_VERSION}-Linux-ARM64.tar.xz" ;; \
      *) echo "Unsupported platform: $TARGETPLATFORM" && exit 1 ;; \
    esac && \
    wget -q "$LLVM_URL" -O llvm.tar.xz
RUN mkdir -p /llvm && tar -xvf llvm.tar.xz -C /llvm --strip-components=1 >/dev/null

# 定义中转目录
ENV LLVM_STAGE_DIR=/stage
RUN mkdir -p $LLVM_STAGE_DIR/bin $LLVM_STAGE_DIR/lib

# clang
RUN cp -P /llvm/bin/clang /llvm/bin/clang++ /llvm/bin/clang-21 $LLVM_STAGE_DIR/bin
RUN cp -R /llvm/lib/clang $LLVM_STAGE_DIR/lib
# clang tools
RUN cp /llvm/bin/clangd /llvm/bin/clang-format $LLVM_STAGE_DIR/bin

# ---------- 第二阶段：构建最小C++编译环境 ----------
# C++ 最小env: 编译器, c库, c++库, ld, ar
FROM debian:12 AS builder-basic

# clang
COPY --from=llvm /stage/bin /usr/bin
COPY --from=llvm /stage/lib /usr/lib

RUN apt-get update > /dev/null && \
    # install c++ env: libc, libstdc++, binutils(ld, ar, as)
    apt-get install -y --no-install-recommends libc6-dev libstdc++-12-dev binutils > /dev/null && \
    # extra tools
    apt-get install -y --no-install-recommends gdb git >/dev/null && \
    # 减少git提示信息
    git config --global advice.detachedHead false && \
    ldconfig


# ---------- 第三阶段：构建编译环境 ----------
# 编译结果放在/usr/local中

FROM builder-basic AS compiler

# Dockerfile(BuildKit)内置参数
ARG TARGETPLATFORM

# 编译阶段临时需要的工具
RUN apt-get install -y --no-install-recommends wget ca-certificates unzip > /dev/null

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


# ---------- 第四阶段：编译第三方库 ----------

# CMAKE Command
ENV BUILD="cmake -S . -B build -G Ninja -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_CXX_STANDARD=20 -DCMAKE_RULE_MESSAGES=OFF -DCMAKE_INSTALL_MESSAGE=NEVER"

# ---- Protobuf ----
RUN git clone --branch v31.1 --depth 1 https://github.com/protocolbuffers/protobuf.git /protobuf > /dev/null
RUN cd /protobuf && git submodule update --init --recursive
RUN cd /protobuf && $BUILD -Dprotobuf_BUILD_SHARED_LIBS=OFF -Dprotobuf_BUILD_TESTS=OFF > /dev/null
RUN cd /protobuf && cmake --build build -j$(nproc) > /dev/null
RUN cd /protobuf && cmake --install build > /dev/null

# ---- PostgreSQL Client ----
RUN apt-get install -y --no-install-recommends --fix-missing libpq-dev=15.14-0+deb12u1 > /dev/null
RUN git clone --branch 7.10.1 --depth 1 https://github.com/jtv/libpqxx.git /libpqxx > /dev/null
RUN cd /libpqxx && $BUILD -DBUILD_SHARED_LIBS=off -DSKIP_BUILD_TEST=on -DBUILD_DOC=off > /dev/null
RUN cd /libpqxx && cmake --build build -j$(nproc) > /dev/null
RUN cd /libpqxx && cmake --install build > /dev/null

# ---- spdlog ----
RUN git clone --branch v1.15.3 --depth 1 https://github.com/gabime/spdlog.git /spdlog > /dev/null
RUN cd /spdlog && $BUILD -DSPDLOG_BUILD_SHARED=OFF -DSPDLOG_BUILD_EXAMPLE=OFF > /dev/null
RUN cd /spdlog && cmake --build build -j$(nproc) > /dev/null
RUN cd /spdlog && cmake --install build > /dev/null

# ---- hiredis ----
RUN git clone --branch v1.3.0 --depth 1 https://github.com/redis/hiredis.git /hiredis > /dev/null
RUN cd /hiredis && $BUILD -DBUILD_SHARED_LIBS=OFF -DDISABLE_TESTS=ON > /dev/null
RUN cd /hiredis && cmake --build build -j$(nproc) > /dev/null
RUN cd /hiredis && cmake --install build > /dev/null

# ---- redis-plus-plus ----
RUN git clone --branch 1.3.14 --depth 1 https://github.com/sewenew/redis-plus-plus.git /rpp > /dev/null
RUN cd /rpp && $BUILD -DREDIS_PLUS_PLUS_BUILD_SHARED=OFF -DREDIS_PLUS_PLUS_BUILD_TEST=OFF > /dev/null
RUN cd /rpp && cmake --build build -j$(nproc) > /dev/null
RUN cd /rpp && cmake --install build > /dev/null

# ---- asio (header only) ----
RUN git clone --branch asio-1-34-2 --depth 1 https://github.com/chriskohlhoff/asio.git /asio > /dev/null
RUN cd /asio/asio && cp include/asio.hpp /usr/local/include && cp -r include/asio /usr/local/include

# ---- tomlplusplus ----
RUN git clone --branch v3.4.0 --depth 1 https://github.com/marzer/tomlplusplus.git /tomlplusplus > /dev/null
RUN cd /tomlplusplus && $BUILD -DBUILD_SHARED_LIBS=OFF > /dev/null
RUN cd /tomlplusplus && cmake --build build -j$(nproc) > /dev/null
RUN cd /tomlplusplus && cmake --install build > /dev/null


# ---------- 第五阶段：发布 ----------
FROM builder-basic

# 获取compiler的结果
COPY --from=compiler /usr/local/bin /usr/local/bin
COPY --from=compiler /usr/local/lib /usr/local/lib
COPY --from=compiler /usr/local/include /usr/local/include
