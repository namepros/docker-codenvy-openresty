FROM zenexer/codenvy:latest

ARG RESTY_VERSION="1.11.2.3"
ARG RESTY_LUAROCKS_VERSION="2.4.2"
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
    --user=www-data \
    --group=www-data \
    --pid-path=/run/nginx.pid \
    --sbin-path=/usr/local/sbin \
    --http-log-path=/var/log/nginx/access.log \
    --error-log-path=/var/log/nginx/error.log \
    ${RESTY_CONFIG_OPTIONS} \
    -j${RESTY_MAKE_THREADS} \
    "

RUN true \
    && DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        # OpenResty
        build-essential \
        ca-certificates \
        curl \
        libgd-dev \
        libncurses5-dev \
        libreadline-dev \
        make \
        unzip \
        zlib1g-dev \
        libpcre3-dev \
        libssl1.0-dev \
    && DEBIAN_FRONTEND=noninteractive apt-get -y autoremove \
    && DEBIAN_FRONTEND=noninteractive apt-get -y clean \
    && true

# Each of these takes a while; separate them to create checkpoints
RUN true \
    && cd /tmp \
    && curl -fSL https://openresty.org/download/openresty-"$RESTY_VERSION".tar.gz -o openresty-"$RESTY_VERSION".tar.gz \
    && tar xf openresty-"$RESTY_VERSION".tar.gz \
    && cd /tmp/openresty-"$RESTY_VERSION" \
    && ./configure \
        --with-cc-opt='-g -O2 -fPIE -fstack-protector-strong -Wformat -Werror=format-security -D_FORTIFY_SOURCE=2' \
        --with-ld-opt='-Wl,-Bsymbolic-functions -fPIE -pie -Wl,-z,relro -Wl,-z,now' \
        $_RESTY_CONFIG_OPTIONS \
    && true
RUN true \
    && cd /tmp/openresty-"$RESTY_VERSION" \
    && make -j"$RESTY_MAKE_THREADS" \
    && true
RUN true \
    && cd /tmp/openresty-"$RESTY_VERSION" \
    && make install \
    && rm -rf \
        openresty-"$RESTY_VERSION".tar.gz \
        openresty-"$RESTY_VERSION" \
        luarocks-"$RESTY_LUAROCKS_VERSION".tar.gz \
        luarocks-"$RESTY_LUAROCKS_VERSION" \
    && ln -s /dev/stdout /var/log/nginx/access.log \
    && ln -s /dev/stderr /var/log/nginx/error.log \
    && true

RUN true \
    && cd /tmp \
    && curl -fSL http://luarocks.org/releases/luarocks-"$RESTY_LUAROCKS_VERSION".tar.gz -o luarocks-"$RESTY_LUAROCKS_VERSION".tar.gz \
    && tar xf luarocks-"$RESTY_LUAROCKS_VERSION".tar.gz \
    && cd /tmp/luarocks-"$RESTY_LUAROCKS_VERSION" \
    && ./configure \
        --prefix=/usr/local/openresty/luajit \
        --with-lua=/usr/local/openresty/luajit \
        --lua-suffix="$(for i in /usr/local/openresty/luajit/bin/luajit-*; do i="$(basename "$i")"; echo "${i#lua}"; break; done)" \
        --with-lua-include="$(for i in /usr/local/openresty/luajit/include/luajit-*; do echo "$i"; break; done)" \
    && make -j"$RESTY_MAKE_THREADS" build \
    && make install \
    && cd /tmp \
    && rm -rf \
        luarocks-"$RESTY_LUAROCKS_VERSION".tar.gz \
        luarocks-"$RESTY_LUAROCKS_VERSION" \
    && true

EXPOSE 80 443
EXPOSE 22 4403
WORKDIR /projects
ENTRYPOINT ["/home/user/entrypoint.sh"]
CMD echo Running && tail -f /dev/null
