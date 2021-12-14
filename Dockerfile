FROM gcc:10
WORKDIR /
RUN apt update && \
    echo "=========> make protobuf" && \
    apt install git autoconf automake libtool curl make g++ unzip -y && \
    wget https://github.com/protocolbuffers/protobuf/releases/download/v3.7.1/protobuf-cpp-3.7.1.tar.gz && \
    tar xf protobuf-cpp-* && rm protobuf-cpp-* && \
    cd protobuf* && \
    ./autogen.sh && \
    ./configure --prefix=/third_sites/protobuf --enable-static=no --disable-option-checking --disable-dependency-tracking --disable-64bit-solaris DIST_LANG=cpp && \
    make && make install && \
    cd / && \
    echo -e "=========> make glog" && \
    apt install cmake -y && \
    git clone --branch v0.5.0 https://github.com/google/glog.git && cd glog && \
    cmake -S . -B build -G "Unix Makefiles" -D CMAKE_INSTALL_PREFIX=/third_sites/glog && \
    cmake --build build && \
    cmake --build build --target install && \
    cd / && \
    echo -e "=========> make odbc" && \
    wget ftp://ftp.unixodbc.org/pub/unixODBC/unixODBC-2.3.9.tar.gz && \
    tar xf unixODBC*.tar.gz && rm unixODBC*.tar.gz && \
    cd unixODBC* && \
    ./configure --prefix=/third_sites/odbc --enable-static=no --enable-gui=no --enable-iconv=yes --with-iconv-char-enc=GB18030 && \
    make && make install && \
    cd / && \
    echo -e "=========> make hiredis" && \
    git clone --branch v1.0.2 https://github.com/redis/hiredis.git && cd hiredis && \
    make PREFIX=/third_sites/hiredis && \
    make install PREFIX=/third_sites/hiredis && \
    cd / && \
    echo -e "=========> make redis-cpp-cpuu" && \
    git clone --branch 1.3.2 https://github.com/sewenew/redis-plus-plus.git && \
    cd redis-plus-plus && \
    mkdir build && cd build && \
    cmake -DCMAKE_PREFIX_PATH=/third_sites/hiredis -DCMAKE_INSTALL_PREFIX=/third_sites/redis-plus-plus -DREDIS_PLUS_PLUS_CXX_STANDARD=11 .. && \
    make && make install && \
    cd /    


COPY docker.sh /docker.sh
COPY for_rep_server_env.sh /for_rep_server_env.sh
ENTRYPOINT ["/docker.sh"]