FROM ubuntu:17.04

ARG RESTY_VERSION="1.11.2.3"
ARG RESTY_LUAROCKS_VERSION="2.4.2"
ARG RESTY_OPENSSL_VERSION="1.0.2k"
ARG RESTY_PCRE_VERSION="8.40"
ARG RESTY_MAKE_THREADS="2"
ARG RESTY_CONFIG_OPTIONS="\
    --with-file-aio \
    --with-http_auth_request_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-ipv6 \
    --with-md5-asm \
    --with-pcre-jit \
    --with-sha1-asm \
    --with-stream \
    --with-stream_ssl_module \
    --with-threads \
    --without-http_xss_module \
    --without-http_coolkit_module \
    --without-http_srcache_module \
    --without-http_memc_module \
    --without-http_redis2_module \
    --without-http_redis_module \
    --without-http_rds_json_module \
    --without-http_rds_csv_module \
    "
# These are not intended to be user-specified
ARG _RESTY_CONFIG_OPTIONS="\
    --with-cc-opt='-g -O2 -fPIE -fstack-protector-strong -Wformat -Werror=format-security -D_FORTIFY_SOURCE=2' \
    --with-ld-opt='-Wl,-Bsymbolic-functions -fPIE -pie -Wl,-z,relro -Wl,-z,now' \
    --user=www-data \
    --group=www-data \
    --pid-path=/run/nginx.pid \
    --sbin-path=/usr/local/sbin \
    --bin-path=/usr/local/bin \
    --http-log-path=/var/log/nginx/access.log \
    --error-log-path=/var/log/nginx/error.log \
    --with-openssl=/tmp/openssl-${RESTY_OPENSSL_VERSION} \
    --with-pcre=/tmp/pcre-${RESTY_PCRE_VERSION} \
    ${RESTY_CONFIG_OPTIONS} \
    -j${RESTY_MAKE_THREADS} \
    "

RUN true \
    && DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        libgd-dev \
        libgeoip-dev \
        libncurses5-dev \
        libperl-dev \
        libreadline-dev \
        libxslt1-dev \
        make \
        perl \
        unzip \
        zlib1g-dev \
    && cd /tmp \
    && curl -fSL https://www.openssl.org/source/openssl-"$RESTY_OPENSSL_VERSION".tar.gz -o openssl-"$RESTY_OPENSSL_VERSION".tar.gz \
    && tar xf openssl-"$RESTY_OPENSSL_VERSION".tar.gz \
    && curl -fSL https://ftp.pcre.org/pub/pcre/pcre-"$RESTY_PCRE_VERSION".tar.gz -o pcre-"$RESTY_PCRE_VERSION".tar.gz \
    && tar xf pcre-"$RESTY_PCRE_VERSION".tar.gz \
    && curl -fSL https://openresty.org/download/openresty-"$RESTY_VERSION".tar.gz -o openresty-"$RESTY_VERSION".tar.gz \
    && tar xf openresty-"$RESTY_VERSION".tar.gz \
    && cd /tmp/openresty-"$RESTY_VERSION" \
    && ./configure $_RESTY_CONFIG_OPTIONS \
    && make -j"$RESTY_MAKE_THREADS" \
    && make -j"$RESTY_MAKE_THREADS" install \
    && cd - > /dev/null \
    && rm -rf \
        openssl-"$RESTY_OPENSSL_VERSION" \
        openssl-"$RESTY_OPENSSL_VERSION".tar.gz \
        openresty-"$RESTY_VERSION".tar.gz openresty-"$RESTY_VERSION" \
        pcre-"$RESTY_PCRE_VERSION".tar.gz pcre-"$RESTY_PCRE_VERSION" \
    && curl -fSL http://luarocks.org/releases/luarocks-"$RESTY_LUAROCKS_VERSION".tar.gz -o luarocks-"$RESTY_LUAROCKS_VERSION".tar.gz \
    && tar xf luarocks-"$RESTY_LUAROCKS_VERSION".tar.gz \
    && cd luarocks-"$RESTY_LUAROCKS_VERSION" \
    && ./configure \
        --prefix=/usr/local/openresty/luajit \
        --with-lua=/usr/local/openresty/luajit \
        --lua-suffix="$(for i in /usr/local/openresty/luajit/bin/luajit-*; do i="$(basename "$i")"; echo "${i#lua}"; break; done)" \
        --with-lua-include="$(for i in /usr/local/openresty/luajit/include/luajit-*; do echo "$i"; break; done)" \
    && make -j"$RESTY_MAKE_THREADS" build \
    && make install \
    && cd - > /dev/null \
    && rm -rf luarocks-"$RESTY_LUAROCKS_VERSION" luarocks-"$RESTY_LUAROCKS_VERSION".tar.gz \
    && DEBIAN_FRONTEND=noninteractive apt-get autoremove -y \
    && mkdir /var/log/nginx \
    && ln -s /dev/stdout /var/nginx/logs/access.log \
    && ln -s /dev/stderr /var/nginx/logs/error.log \
    && true

EXPOSE 80 443


#################
#### Codenvy ####
#################

# Copyright (c) 2012-2016 Codenvy, S.A.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# Contributors:
# Codenvy, S.A. - initial API and implementation
#
# Modified by NamePros
ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk-amd64
RUN true \
    && DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get -y install \
        openssh-server \
        sudo \
        procps \
        wget \
        unzip \
        mc \
        ca-certificates \
        curl \
        software-properties-common \
        python-software-properties \
        bash-completion \
        git \
        subversion \
        openjdk-8-jdk-headless \
    && mkdir /var/run/sshd \
    && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \
    && echo "%sudo ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && useradd -u 1000 -G users,sudo -d /home/user --shell /bin/bash -m user \
    && usermod -p "*" user \
    && apt-get -y autoremove \
    && sudo update-ca-certificates -f \
    && sudo sudo /var/lib/dpkg/info/ca-certificates-java.postinst configure \
    && apt-get -y clean \
    && true

ENV LANG en_US.UTF-8
USER user
RUN true \
    && sudo locale-gen en_US.UTF-8 \
    && svn --version > /dev/null \
    && cd /home/user \
    && echo "#! /bin/bash\n set -e\n sudo /usr/sbin/sshd -D &\n exec \"\$@\"" > /home/user/entrypoint.sh \
    && chmod +x /home/user/entrypoint.sh \
    && sed -i 's/# store-passwords = no/store-passwords = yes/g' /home/user/.subversion/servers \
    && sed -i 's/# store-plaintext-passwords = no/store-plaintext-passwords = yes/g' /home/user/.subversion/servers \
    && true
EXPOSE 22 4403
WORKDIR /projects
ENTRYPOINT ["/home/user/entrypoint.sh"]
CMD tail -f /dev/null
