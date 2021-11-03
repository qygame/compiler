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
    cd /

COPY docker.sh /docker.sh
COPY for_rep_server_env.sh /for_rep_server_env.sh
ENTRYPOINT ["/docker.sh"]