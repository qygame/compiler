# syntax=docker/dockerfile:1.5
FROM gcc:14.3
WORKDIR /

# Dockerfile(BuildKit)内置参数
ARG TARGETPLATFORM

RUN git config --global advice.detachedHead false

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
RUN git clone --branch v31.1 https://github.com/protocolbuffers/protobuf.git /home/protobuf && cd /home/protobuf && \
    git submodule update --init --recursive && \
    cmake -S . -B build -Dprotobuf_BUILD_TESTS=OFF -Dprotobuf_BUILD_SHARED_LIBS=ON -DCMAKE_CXX_STANDARD=23 -DCMAKE_RULE_MESSAGES=OFF -DCMAKE_INSTALL_MESSAGE=NEVER >/dev/null && \
    cmake --build build -j$(nproc) -- -s > /dev/null && cmake --install build > /dev/null && \
    rm -rf /home/protobuf

# ---- MySQL Connector/C++ ----
RUN case "$TARGETPLATFORM" in \
      "linux/amd64") MYSQL_URL="https://cdn.mysql.com/archives/mysql-connector-c++/mysql-connector-c++-9.3.0-linux-glibc2.28-x86-64bit.tar.gz" ;; \
      "linux/arm64") MYSQL_URL="https://cdn.mysql.com/archives/mysql-connector-c++/mysql-connector-c++-9.3.0-linux-glibc2.28-aarch64.tar.gz" ;; \
      *) echo "Unsupported platform: $TARGETPLATFORM" && exit 1 ;; \
    esac && \
    wget -q "$MYSQL_URL" && \
    tar -xzf mysql-connector*.tar.gz  && rm mysql-connector*.tar.gz && \
    mkdir -p /usr/local/include && cp -r mysql-connector*/include/* /usr/local/include/ && \
    mkdir -p /usr/local/lib64   && cp -r mysql-connector*/lib64/*   /usr/local/lib64/ && \
    rm -rf mysql-connector*

# ---- glog ----
RUN git clone --branch v0.7.1 https://github.com/google/glog.git /home/glog && cd /home/glog && \
    cmake -S . -B build -DBUILD_TESTING=OFF -DWITH_GTEST=OFF -G "Unix Makefiles" -DCMAKE_RULE_MESSAGES=OFF -DCMAKE_INSTALL_MESSAGE=NEVER >/dev/null && \
    cmake --build build -j$(nproc) -- -s > /dev/null && cmake --install build > /dev/null && \
    rm -rf /home/glog

# ---- hiredis ----
RUN git clone --branch v1.3.0 https://github.com/redis/hiredis.git /home/hiredis && cd /home/hiredis && \
    cmake -S . -B build -DDISABLE_TESTS=ON -DCMAKE_RULE_MESSAGES=OFF -DCMAKE_INSTALL_MESSAGE=NEVER >/dev/null && \
    cmake --build build -j$(nproc) -- -s > /dev/null && cmake --install build > /dev/null && \
    rm -rf /home/hiredis

# ---- redis-plus-plus ----
RUN git clone --branch 1.3.14 https://github.com/sewenew/redis-plus-plus.git /home/redis-plus-plus && cd /home/redis-plus-plus && \
    cmake -S . -B build -DREDIS_PLUS_PLUS_BUILD_TEST=OFF -DREDIS_PLUS_PLUS_CXX_STANDARD=17 -DCMAKE_RULE_MESSAGES=OFF -DCMAKE_INSTALL_MESSAGE=NEVER >/dev/null && \
    cmake --build build -j$(nproc) -- -s > /dev/null && cmake --install build > /dev/null && \
    rm -rf /home/redis-plus-plus

# ---- asio ----
RUN git clone --branch asio-1-34-2 https://github.com/chriskohlhoff/asio.git /home/asio && cd /home/asio/asio && \
    ./autogen.sh && ./configure && \
    make -s > /dev/null  && make install >/dev/null && \
    rm -rf /home/asio

# ---- clangd ----
RUN wget -q https://github.com/clangd/clangd/releases/download/19.1.2/clangd-linux-19.1.2.zip && \
    unzip -q clangd*.zip  && rm clangd*.zip  && \
    cp -r clangd*/bin/* /usr/local/bin/ && \
    cp -r clangd*/lib/* /usr/local/lib/ && \
    rm -rf clangd*

RUN ldconfig
