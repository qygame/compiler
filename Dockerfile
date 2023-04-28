FROM gcc:12.2
WORKDIR /

COPY env.sh /env.sh

RUN apt update && apt install curl git make g++ unzip cmake -y

RUN echo -e "=========> make protobuf" &&  cd / && \
    git clone --branch v22.3 https://github.com/protocolbuffers/protobuf.git protobuf && cd protobuf && \
    git submodule update --init --recursive && \
    cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/third_sites/protobuf -Dprotobuf_BUILD_TESTS=OFF -Dprotobuf_BUILD_SHARED_LIBS=ON -DCMAKE_CXX_STANDARD=20 && \
    cmake --build build && \
    cmake --build build --target install && \
    rm -rf /protobuf

RUN echo -e "=========> make glog" && cd / && \
    git clone --branch v0.5.0 https://github.com/google/glog.git && cd glog && \
    cmake -S . -B build -G "Unix Makefiles" -D CMAKE_INSTALL_PREFIX=/third_sites/glog && \
    cmake --build build && \
    cmake --build build --target install && \
    rm -rf /glog

RUN echo -e "=========> make odbc" && cd / && \
    wget ftp://ftp.unixodbc.org/pub/unixODBC/unixODBC-2.3.9.tar.gz && \
    tar xf unixODBC*.tar.gz && rm unixODBC*.tar.gz && \
    cd unixODBC* && \
    ./configure --prefix=/third_sites/odbc --enable-static=no --enable-gui=no --enable-iconv=yes --with-iconv-char-enc=GB18030 && \
    make && make install && \
    rm -rf /unixODBC*

RUN echo -e "=========> make hiredis" && cd / && \
    git clone --branch v1.0.2 https://github.com/redis/hiredis.git && cd hiredis && \
    make PREFIX=/third_sites/hiredis && \
    make install PREFIX=/third_sites/hiredis && \
    rm -rf /hiredis

RUN echo -e "=========> make redis-cpp-cpuu" && cd / && \
    git clone --branch 1.3.2 https://github.com/sewenew/redis-plus-plus.git && \
    cd redis-plus-plus && \
    mkdir build && cd build && \
    cmake -DCMAKE_PREFIX_PATH=/third_sites/hiredis -DCMAKE_INSTALL_PREFIX=/third_sites/redis-plus-plus -DREDIS_PLUS_PLUS_CXX_STANDARD=11 .. && \
    make && make install && \
    rm -rf /redis-plus-plus

RUN echo "=========> install sql_driver for odbc" && cd / &&\
    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y msodbcsql17 && \
    apt-get install -y unixodbc-dev

RUN --mount=type=secret,id=GIT_AUTH_TOKEN  \
    echo "=========> make qynet" && cd / && \
    token=`cat /run/secrets/GIT_AUTH_TOKEN` && \
    git clone https://$token@github.com/wxlib/handy.git handy && cd handy && \
    make && \
    mv _depends /third_sites/qynet && \
    rm -rf /handy

RUN echo "=========> ./env.sh" && cd / && \
    ./env.sh && rm /env.sh