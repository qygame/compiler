#!/bin/bash

#################### fun ####################
fun_set_include()
{
    export CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH:$1
}

fun_set_lib()
{
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$1
    export LIBRARY_PATH=$LIBRARY_PATH:$1
}

fun_set_bin()
{
    export PATH=$PATH:$1
}

fun_set_odbc_env()
{
    export ODBCSYSINI=$(pwd)/odbc/etc
    export ODBCINI=$(pwd)/odbc/etc/odbc.ini
}
fun_set_odbc_ini()
{
    # odbcinst.ini
    echo "[ODBC Driver 17 for SQL Server]"          >   $(pwd)/odbc/etc/odbcinst.ini
    echo "Description=Microsoft Driver"             >>  $(pwd)/odbc/etc/odbcinst.ini
    echo "Driver=/usr/lib64/libmsodbcsql-17.so"     >>  $(pwd)/odbc/etc/odbcinst.ini
    echo "UsageCount=1"                             >>  $(pwd)/odbc/etc/odbcinst.ini

    # odbc.init
    echo "[mssql]"                                  >   $(pwd)/odbc/etc/odbc.ini
    echo "Driver=ODBC Driver 17 for SQL Server"     >>  $(pwd)/odbc/etc/odbc.ini
    echo "Server=tcp:172.16.238.10,1433"            >>  $(pwd)/odbc/etc/odbc.ini
}
#################### main ####################
cd /third_sites

for file in `ls`
do
    if [ -d "$file/include" ];then
	fun_set_include $(pwd)/$file/include
    fi

    if [ -d "$file/lib" ];then
	fun_set_lib $(pwd)/$file/lib
    fi

    if [ -d "$file/bin" ];then
	fun_set_bin $(pwd)/$file/bin
    fi
done

# odbc
fun_set_odbc_env
fun_set_odbc_ini


# ubuntu && debiang
echo "export CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH"       >> ~/.bashrc
echo "export LIBRARY_PATH=$LIBRARY_PATH"             >> ~/.bashrc
echo "export PATH=$PATH"                             >> ~/.bashrc
echo "export ODBCSYSINI=$ODBCSYSINI"                 >> ~/.bashrc
echo "export ODBCINI=$ODBCINI"                       >> ~/.bashrc
