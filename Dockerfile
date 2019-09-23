FROM aario/centos:7
 
# list in the downloading page  http://dev.mysql.com/downloads/mysql/
# Source Code > Generic Linux (Architecture Independent), Compressed TAR Archive Includes Boost Headers
ENV MysqlVer mysql-8.0.13
ADD ./src/* /usr/local/src/ 
WORKDIR /usr/local/src/${MysqlVer}
RUN yum install -y gcc gcc-c++ make cmake ncurses-devel bison bison-devel openssl-devel openssl

# cmake options https://dev.mysql.com/doc/refman/8.0/en/source-configuration-options.html
#   -DMYSQL_TCP_MYSQL_PORT=3306                           \
#    -DWITH_SYSTEMD=1                                \ cause mysqld_safe not installed
#    -DSYSTEMD_PID_DIR=/etc/aa/lock/mysqld             \  needs -DWITH_SYSTEMD=1  
RUN cmake \
    -DCMAKE_INSTALL_PREFIX=/usr/local/mysql          \
    -DEXTRA_CHARSETS=all                            \
    -DDEFAULT_CHARSET=utf8                          \
    -DDEFAULT_COLLATION=utf8_unicode_ci             \
    -DENABLED_PROFILING=1                           \
    -DINNODB_PAGE_ATOMIC_REF_COUNT=1                \
    -DINSTALL_BINDIR=/usr/local/bin                 \
    -DINSTALL_SBINDIR=/usr/sbin                     \
    -DMYSQL_DATADIR=/var/lib/mysql                  \
    -DMYSQL_TCP_PORT=3306                           \
    -DMYSQL_UNIX_ADDR=/etc/aa/lock/mysqld.sock      \
    -DSYSCONFDIR=/etc/aa                            \   
    -DDOWNLOAD_BOOST=1                              \
    -DWITH_BOOST=/usr/local/src/${MysqlVer}/boost   \
    -DWITH_DEBUG=0                                  \
    -DWITH_MYISAM_STORAGE_ENGINE=1                  \
    -DWITH_INNOBASE_STORAGE_ENGINE=1                \
    -DWITH_BLACKHOLE_STORAGE_ENGINE=1               \
    -DWITH_ARCHIVE_STORAGE_ENGINE=1                 \
    -DWITH_PERFSCHEMA_STORAGE_ENGINE=1              \
    -DWITH_PARTITION_STORAGE_ENGINE=1               \
    -DENABLED_LOCAL_INFILE=1                        \
    -DENABLE_DOWNLOADS=1                            \
    -DWITH_PARTITION_STORAGE_ENGINE=1               \
    -DMYSQL_MAINTAINER_MODE=0                       \
    -DWITH_SSL:STRING=bundled                       \
    -DWITH_ZLIB:STRING=bundled
# Avoid Wrong MySQL package
RUN make && make install

 
RUN yum clean all && rm -rf /var/cache/yum && rm -rf /usr/local/src/*

RUN chown -R docker:docker /usr/sbin/mysqld && chmod u+x /usr/sbin/mysqld
RUN ln -sf /dev/stdout /var/log/dockervol/stdout.log && ln -sf /dev/stderr /var/log/dockervol/stderr.log


# COPY 只能复制当前目录，不复制子目录内容
COPY --chown=docker:docker ./etc/aa/*  /etc/aa/

ENTRYPOINT ["/etc/aa/entrypoint", "/usr/sbin/mysqld", "--user=mysql", "--gtid-mode=ON", "--explicit_defaults_for_timestamp", "--enforce-gtid-consistency"]