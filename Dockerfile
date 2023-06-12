FROM aario/centos:7
 
# list in the downloading page  http://dev.mysql.com/downloads/mysql/
# Source Code > Generic Linux (Architecture Independent), Compressed TAR Archive Includes Boost Headers

ENV MysqlVer mysql-8.0.33
ENV CmakeVer cmake-3.26.4

ADD ./src/* /usr/local/src/

# MySQL has a dependency on the libaio library
RUN yum -y update && yum install -y gcc gcc-c++ make libaio ncurses-devel bison bison-devel openssl-devel openssl
# 安装 cmake3
RUN yum install -y git devtoolset-11-gcc devtoolset-11-gcc-c++ devtoolset-11-binutils
#RUN yum install -y libudev-devel libtirpc libtirpc-devel doxygen
WORKDIR /usr/local/src/${CmakeVer}
RUN ./bootstrap --prefix=/usr/local
RUN make -j$(nproc)
RUN make install

RUN mkdir -p /usr/local/src/${MysqlVer}/build
WORKDIR /usr/local/src/${MysqlVer}/build
# cmake options https://dev.mysql.com/doc/refman/8.0/en/source-configuration-options.html
#   -DMYSQL_TCP_MYSQL_PORT=3306                           \
#    -DWITH_SYSTEMD=1                                \ cause mysqld_safe not installed
#    -DSYSTEMD_PID_DIR=/etc/aa/lock/mysqld             \  needs -DWITH_SYSTEMD=1
RUN cmake .. \
    -DCMAKE_INSTALL_PREFIX=/usr/local/mysql         \
    -DENABLED_PROFILING=1                           \
    -DINSTALL_BINDIR=/usr/local/bin                 \
    -DINSTALL_SBINDIR=/usr/sbin                     \
    -DMYSQL_DATADIR=/var/lib/mysql                  \
    -DMYSQL_TCP_PORT=3306                           \
    -DMYSQL_UNIX_ADDR=/etc/aa/lock/mysqld.sock      \
    -DSYSCONFDIR=/etc/aa                            \
    -DDOWNLOAD_BOOST=1                              \
    -DWITH_BOOST=/usr/local/src/${MysqlVer}/boost   \
    -DWITH_DEBUG=0                                  \
    -DWITH_MYISAM_STORAGE_ENGINE=0                  \
    -DWITH_INNOBASE_STORAGE_ENGINE=1                \
    -DWITH_BLACKHOLE_STORAGE_ENGINE=0               \
    -DWITH_ARCHIVE_STORAGE_ENGINE=0                 \
    -DWITH_PERFSCHEMA_STORAGE_ENGINE=0              \
    -DENABLED_LOCAL_INFILE=1                        \
    -DMYSQL_MAINTAINER_MODE=0                       \
    -DWITH_UNIT_TESTS=1                             \
    -DWITH_SSL=system                               \
    -DWITH_ZLIB:STRING=bundled
RUN make && make install
RUN mv -f /usr/local/src/${MysqlVer}/build/lib/lib* /usr/lib64/
RUN chown -R iwi:iwi /usr/sbin/mysqld && chmod u+x /usr/sbin/mysqld
RUN ln -sf /dev/stdout /var/log/dockervol/stdout.log && ln -sf /dev/stderr /var/log/dockervol/stderr.log

# COPY 只能复制当前目录，不复制子目录内容
COPY --chown=iwi:iwi ./etc/aa/*  /etc/aa/
RUN yum clean all && rm -rf /var/cache/yum && rm -rf /usr/local/src/*
#  "--defaults-file=/etc/aa/my.cnf" 必须紧跟  "/usr/sbin/mysqld" 后面
# 如果没有通过 entrypoint ，没有建立表，就需要先执行 /usr/sbin/mysqld --defaults-file=/etc/aa/my.cnf --initialize   初始化一些文件，才可以继续执行 mysqld ....
ENTRYPOINT ["/etc/aa/entrypoint", "/usr/sbin/mysqld", "--defaults-file=/etc/aa/my.cnf", "--user=iwi","--gtid-mode=ON", "--explicit_defaults_for_timestamp", "--enforce-gtid-consistency"]
