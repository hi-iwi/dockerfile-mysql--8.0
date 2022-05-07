#!/bin/bash
readonly mysqlVer='8.0.29'
readonly cmakeVer='3.20.6'
readonly cmakeTgz="cmake-${cmakeVer}"


download(){
    local f="$1"
    local src="$2"
    if [ -f "$f" ]; then
      return 0
    fi
    wget "$src" -O "$f"
}
# list in the downloading page  http://dev.mysql.com/downloads/mysql/
# Source Code > Generic Linux (Architecture Independent), Compressed TAR Archive Includes Boost Headers
# mysql-boost.tar.gz 解压之后，是没有 -boost 的
download "mysql-boost-${mysqlVer}.tar.gz" "https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-boost-${mysqlVer}.tar.gz"
download "${cmakeTgz}.tar.gz" "https://github.com/Kitware/CMake/releases/download/v${cmakeVer}/${cmakeTgz}.tar.gz"