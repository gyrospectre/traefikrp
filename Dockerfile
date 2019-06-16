FROM openresty/openresty:alpine

ENV \
 LUA_RESTY_SESSION_VERSION=2.23 \
 LUA_RESTY_HTTP_VERSION=0.13 \
 LUA_RESTY_OPENIDC_VERSION=1.7.1 \
 LUA_RESTY_JWT_VERSION=0.2.0 \
 LUA_RESTY_HMAC_VERSION=989f601acbe74dee71c1a48f3e140a427f2d03ae

RUN \
 apk update && apk upgrade && apk add curl && apk add openssl && \
 cd /tmp && \
 curl -sSL https://github.com/bungle/lua-resty-session/archive/v${LUA_RESTY_SESSION_VERSION}.tar.gz | tar xz && \
 curl -sSL https://github.com/pintsized/lua-resty-http/archive/v${LUA_RESTY_HTTP_VERSION}.tar.gz | tar xz  && \
 curl -sSL https://github.com/zmartzone/lua-resty-openidc/archive/v${LUA_RESTY_OPENIDC_VERSION}.tar.gz | tar xz && \
 curl -sSL https://github.com/cdbattags/lua-resty-jwt/archive/v${LUA_RESTY_JWT_VERSION}.tar.gz | tar xz && \
 curl -sSL https://github.com/jkeys089/lua-resty-hmac/archive/${LUA_RESTY_HMAC_VERSION}.tar.gz | tar xz && \
 cp -r /tmp/lua-resty-session-${LUA_RESTY_SESSION_VERSION}/lib/resty/* /usr/local/openresty/lualib/resty/ && \
 cp -r /tmp/lua-resty-http-${LUA_RESTY_HTTP_VERSION}/lib/resty/* /usr/local/openresty/lualib/resty/ && \
 cp -r /tmp/lua-resty-openidc-${LUA_RESTY_OPENIDC_VERSION}/lib/resty/* /usr/local/openresty/lualib/resty/ && \
 cp -r /tmp/lua-resty-jwt-${LUA_RESTY_JWT_VERSION}/lib/resty/* /usr/local/openresty/lualib/resty/ && \
 cp -r /tmp/lua-resty-hmac-${LUA_RESTY_HMAC_VERSION}/lib/resty/* /usr/local/openresty/lualib/resty/ && \
 rm -rf /tmp/* && \
 DAYS=35 && \
 PASS=$(openssl rand -hex 16) && \
 echo 01 > ca.srl && \
 openssl genrsa -des3 -out ca-key.pem -passout pass:$PASS 2048 && \
 openssl req -subj '/CN=*/' -new -x509 -days $DAYS -passin pass:$PASS -key ca-key.pem -out ca.pem && \
 openssl genrsa -des3 -out nginx.key -passout pass:$PASS 2048 && \
 openssl req -new -key nginx.key -out server.csr -passin pass:$PASS -subj "/C=AU/ST=NSW/L=Bathurst/O=OrgName/OU=OhYou/CN=ouyou.com" && \
 openssl x509 -req -days $DAYS -passin pass:$PASS -in server.csr -CA ca.pem -CAkey ca-key.pem -out nginx.crt && \
 openssl rsa -in nginx.key -out nginx.key -passin pass:$PASS && \
 mkdir -p /usr/local/openresty/nginx/ssl && \
 cp nginx.* /usr/local/openresty/nginx/ssl/ && \
 mkdir -p /usr/local/openresty/nginx/conf/hostsites/ && \
 true

# Move scripts into container
COPY start.sh /usr/local/openresty/start.sh

# Move our site NGINX config into container
COPY nginx /usr/local/openresty/nginx/

ENTRYPOINT ["/usr/local/openresty/start.sh"]
