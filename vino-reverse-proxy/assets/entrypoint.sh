#!/bin/sh

set -ex

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

basic_auth_config=''
if [ "$USE_BASIC_AUTH" = "true" ]; then
  htpasswd -Bbn "$BASIC_AUTH_USERNAME" "$BASIC_AUTH_PASSWORD" > /etc/nginx/auth.htpasswd
  basic_auth_config='
        # Basic Auth
        limit_except OPTIONS {
            auth_basic "Restricted";
            auth_basic_user_file "auth.htpasswd";
        }'
fi
export basic_auth_config

tls_config='listen       8000;'

if [ "$USE_TLS" = "true" ]; then
  mkdir -p /etc/ssl/certs
  mkdir -p /etc/ssl/private

  echo "$TLS_CRT" > /etc/ssl/certs/redfish-auth.crt
  echo "$TLS_KEY" > /etc/ssl/private/redfish-auth.key

  tls_config='listen 443 ssl http2 default_server;
    listen [::]:443 ssl http2 default_server;
    ssl_certificate /etc/ssl/certs/redfish-auth.crt;
    ssl_certificate_key /etc/ssl/private/redfish-auth.key;'
fi
export tls_config

vars='$basic_auth_config:$tls_config'
envsubst "$vars" </default.conf.tpl >/etc/nginx/conf.d/default.conf

cat /etc/nginx/conf.d/default.conf

nginx -g 'daemon off;'
