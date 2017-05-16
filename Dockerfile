FROM centos:centos7
MAINTAINER Marcin Ryzycki marcin@m12.io, Przemyslaw Ozgo linux@ozgo.info

ENV HAPROXY_MJR_VERSION=1.7
ENV HAPROXY_VERSION=1.7.5

#install haproxy with new enough openssl & lua
RUN \
  yum install -y epel-release && \
  yum update -y && \
  `# Install build tools. Note: perl needed to compile openssl...` \
  yum install -y inotify-tools wget tar gzip make gcc perl pcre-devel zlib-devel readline-devel && \

  `# Install newest openssl...` \
  wget -O /tmp/openssl.tgz https://www.openssl.org/source/openssl-1.0.2-latest.tar.gz && \
  tar -zxf /tmp/openssl.tgz -C /tmp && \
  cd /tmp/openssl-* && \
  ./config --prefix=/usr \
    --openssldir=/etc/ssl \
    --libdir=lib          \
    no-shared zlib-dynamic && \
  make && make install_sw && \
  cd && rm -rf /tmp/openssl* && \

  `# Install LUA...` \
  cd /usr/src && \
  curl -R -O http://www.lua.org/ftp/lua-5.3.0.tar.gz && \
  tar zxf lua-5.3.0.tar.gz && \
  cd lua-5.3.0 && \
  make linux && \
  make INSTALL_TOP=/opt/lua53 install && \
  rm -rf /usr/src/lua* && \

  `# Install HAProxy...` \
  wget -O /tmp/haproxy.tgz http://www.haproxy.org/download/${HAPROXY_MJR_VERSION}/src/haproxy-${HAPROXY_VERSION}.tar.gz && \
  tar -zxvf /tmp/haproxy.tgz -C /tmp && \
  cd /tmp/haproxy-* && \
  make \
    TARGET=linux2628 USE_LINUX_TPROXY=1 USE_ZLIB=1 USE_REGPARM=1 USE_PCRE=1 USE_PCRE_JIT=1 \
    USE_OPENSSL=1 SSL_INC=/usr/include SSL_LIB=/usr/lib ADDLIB=-ldl \
    USE_LUA=yes LUA_LIB=/opt/lua53/lib/ LUA_INC=/opt/lua53/include/ LDFLAGS=-ldl \
    CFLAGS="-O2 -g -fno-strict-aliasing -DTCP_USER_TIMEOUT=18" && \
  make install && \
  rm -rf /tmp/haproxy* && \

  `# Configure HAProxy...` \
  mkdir -p /var/lib/haproxy && \
  groupadd haproxy && adduser haproxy -g haproxy && chown -R haproxy:haproxy /var/lib/haproxy && \
  `# Generate dummy SSL cert for HAProxy...` \
  openssl genrsa -out /etc/ssl/dummy.key 2048 && \
  openssl req -new -key /etc/ssl/dummy.key -out /etc/ssl/dummy.csr -subj "/C=GB/L=London/O=Company Ltd/CN=haproxy" && \
  openssl x509 -req -days 3650 -in /etc/ssl/dummy.csr -signkey /etc/ssl/dummy.key -out /etc/ssl/dummy.crt && \
  cat /etc/ssl/dummy.crt /etc/ssl/dummy.key > /etc/ssl/dummy.pem && \

  `# Clean up: build tools...` \
  yum remove -y make gcc pcre-devel && \
  yum clean all

#install collectd
RUN yum install -y collectd

#install hatop
RUN \
  wget https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/hatop/hatop-0.7.7.tar.gz && \
  tar xvf hatop-0.7.7.tar.gz && \
  cd hatop-0.7.7 && \
  install -m 755 bin/hatop /usr/local/bin

COPY container-files /

RUN chmod +x /bootstrap.sh

ADD https://raw.githubusercontent.com/signalfx/collectd-haproxy/master/haproxy.py /etc/collectd/haproxy.py

ENV HAPROXY_CONFIG /etc/haproxy/haproxy.cfg
#set TERM enviroment for hatop
ENV TERM linux

EXPOSE 80 443

CMD ["/bootstrap.sh"]
