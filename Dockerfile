FROM gcc:13.2
WORKDIR /

RUN apt update && apt install curl git make g++ unzip cmake -y

RUN echo -e "=========> make protobuf" &&  cd /home && \
    cmake --version && \
    git clone --branch v25.0 https://github.com/protocolbuffers/protobuf.git protobuf && cd protobuf && \
    git submodule update --init --recursive && \
    cmake -S . -B build -Dprotobuf_BUILD_TESTS=OFF -Dprotobuf_BUILD_SHARED_LIBS=ON -DCMAKE_CXX_STANDARD=20 && \
    cmake --build build && \
    cmake --build build --target install && \
    rm -rf /home/protobuf

RUN echo -e "=========> make MySQL Connector/C++" && cd /home && \
    git clone https://github.com/qydocker/mysql-connector-cpp.git mysql && cd mysql && \
    cmake -S . -B build -DWITH_PROTOBUF=system -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=ins_build && \
    cmake --build build && \
    cmake --build build --target install --config Release && \
    mv ins_build/include/mysqlx /usr/local/include/ && \
    mv ins_build/lib64/* /usr/local/lib && \
    rm -rf /home/mysql

RUN echo -e "=========> make glog" && cd /home && \
    git clone --branch v0.6.0 https://github.com/google/glog.git && cd glog && \
    cmake -S . -B build -G "Unix Makefiles" && \
    cmake --build build && \
    cmake --build build --target install && \
    rm -rf /home/glog

RUN echo -e "=========> make hiredis" && cd /home && \
    git clone --branch v1.2.0 https://github.com/redis/hiredis.git && cd hiredis && \
    make && \
    make install && \
    rm -rf /home/hiredis

RUN echo -e "=========> make redis-cpp-cpuu" && cd /home && \
    git clone --branch 1.3.10 https://github.com/sewenew/redis-plus-plus.git && \
    cd redis-plus-plus && \
    mkdir build && cd build && \
    cmake -DREDIS_PLUS_PLUS_CXX_STANDARD=11 .. && \
    make && make install && \
    rm -rf /home/redis-plus-plus

RUN echo "=========> install asio" && cd /home &&\
    git clone --branch asio-1-28-2 https://github.com/chriskohlhoff/asio.git && \
    cd asio/asio && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make install && \
    rm -rf /home/asio    

RUN echo "=========> install lsp-server: clangd" && cd /home &&\
    wget https://github.com/clangd/clangd/releases/download/17.0.3/clangd-linux-17.0.3.zip && \
    unzip -q clangd*.zip  && rm clangd*.zip  && \
    mv clangd*/bin/clangd /usr/local/bin/ && \
    mv clangd*/lib/clang /usr/local/lib/ && \
    rm -rf /home/clangd*

RUN ldconfig
