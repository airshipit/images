server {
    server_name  localhost;
    $tls_config

    location / {
        proxy_pass  http://localhost:5000/;
        proxy_set_header Authorization $http_authorization;
        proxy_pass_header  Authorization;
        $basic_auth_config
    }
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
