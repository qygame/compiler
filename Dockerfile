FROM gcc:13.2
WORKDIR /

COPY env.sh /home/env.sh

RUN apt update && apt install curl git make g++ unzip cmake -y

RUN echo -e "=========> make protobuf" &&  cd /home && \
    cmake --version && \
    git clone --branch v25.0 https://github.com/protocolbuffers/protobuf.git protobuf && cd protobuf && \
    git submodule update --init --recursive && \
    cmake -S . -B build -Dprotobuf_BUILD_TESTS=OFF -Dprotobuf_BUILD_SHARED_LIBS=ON -DCMAKE_CXX_STANDARD=20 && \
    cmake --build build && \
    cmake --build build --target install && \
    rm -rf /home/protobuf

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

RUN echo -e "=========> make odbc" && cd /home && \
    wget ftp://ftp.unixodbc.org/pub/unixODBC/unixODBC-2.3.12.tar.gz && \
    tar xf unixODBC*.tar.gz && rm unixODBC*.tar.gz && \
    cd unixODBC* && \
    ./configure --enable-static=no --enable-gui=no --enable-iconv=yes --with-iconv-char-enc=GB18030 && \
    make && make install && \
    rm -rf /home/unixODBC*

RUN echo "=========> install sql_driver for odbc" && cd /home &&\
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg && \
    curl https://packages.microsoft.com/config/debian/12/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y msodbcsql18 && \
    apt-get install -y unixodbc-dev

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

RUN echo "=========> ./env.sh" && cd /home && \
    ./env.sh && rm env.sh
