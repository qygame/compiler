FROM gcc:14.3
WORKDIR /

RUN git config --global advice.detachedHead false

RUN echo -e "=========> download cmake" && cd /home && \
    wget -q https://github.com/Kitware/CMake/releases/download/v3.31.7/cmake-3.31.7-linux-x86_64.sh && \
    chmod 775 cmake*.sh && mv cmake*.sh cmake.sh && \
    ./cmake.sh --skip-license --prefix=/usr/local && \
    rm cmake.sh

RUN echo -e "=========> make protobuf" && cd /home && \
    git clone --branch v31.1 https://github.com/protocolbuffers/protobuf.git protobuf && cd protobuf && \
    git submodule update --init --recursive && \
    cmake -S . -B build -Dprotobuf_BUILD_TESTS=OFF -Dprotobuf_BUILD_SHARED_LIBS=ON -DCMAKE_CXX_STANDARD=23 -DCMAKE_RULE_MESSAGES=OFF -DCMAKE_INSTALL_MESSAGE=NEVER && \
    cmake --build build && \
    cmake --build build --target install && \
    rm -rf /home/protobuf

RUN echo -e "=========> make MySQL Connector/C++" && cd /home && \
    git clone --branch 9.3.0 https://github.com/mysql/mysql-connector-cpp.git mysql && cd mysql && \
    cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=ins_build -DCMAKE_CXX_STANDARD=23 -DCMAKE_RULE_MESSAGES=OFF -DCMAKE_INSTALL_MESSAGE=NEVER && \
    cmake --build build && \
    cmake --build build --target install --config Release && \
    mv ins_build/include/mysqlx /usr/local/include/ && \
    mv ins_build/lib64/* /usr/local/lib && \
    rm -rf /home/mysql

RUN echo -e "=========> make glog" && cd /home && \
    git clone --branch v0.7.1 https://github.com/google/glog.git && cd glog && \
    cmake -S . -B build -DBUILD_TESTING=OFF -DWITH_GTEST=OFF -G "Unix Makefiles" -DCMAKE_RULE_MESSAGES=OFF -DCMAKE_INSTALL_MESSAGE=NEVER && \
    cmake --build build && \
    cmake --build build --target install && \
    rm -rf /home/glog

RUN echo -e "=========> make hiredis" && cd /home && \
    git clone --branch v1.3.0 https://github.com/redis/hiredis.git && cd hiredis && \
    cmake -S . -B build -DDISABLE_TESTS=ON -DCMAKE_RULE_MESSAGES=OFF -DCMAKE_INSTALL_MESSAGE=NEVER && \
    cmake --build build && \
    cmake --build build --target install && \
    rm -rf /home/hiredis

RUN echo -e "=========> make redis-plus-plus" && cd /home && \
    git clone --branch 1.3.14 https://github.com/sewenew/redis-plus-plus.git && cd redis-plus-plus && \
    cmake -S . -B build -DREDIS_PLUS_PLUS_BUILD_TEST=OFF -DREDIS_PLUS_PLUS_CXX_STANDARD=17 -DCMAKE_RULE_MESSAGES=OFF -DCMAKE_INSTALL_MESSAGE=NEVER && \
    cmake --build build && \
    cmake --build build --target install && \
    rm -rf /home/redis-plus-plus

RUN echo "=========> install asio" && cd /home &&\
    git clone --branch asio-1-34-2 https://github.com/chriskohlhoff/asio.git && cd asio/asio && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make install && \
    rm -rf /home/asio

RUN echo "=========> install lsp-server: clangd" && cd /home &&\
    wget -q https://github.com/clangd/clangd/releases/download/19.1.2/clangd-linux-19.1.2.zip && \
    unzip -q clangd*.zip  && rm clangd*.zip  && \
    mv clangd*/bin/clangd /usr/local/bin/ && \
    mv clangd*/lib/clang /usr/local/lib/ && \
    rm -rf /home/clangd*

RUN ldconfig
