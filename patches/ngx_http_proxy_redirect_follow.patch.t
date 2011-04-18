#!/usr/bin/perl

# (C) Kirill A. Korinskiy

# Tests for ngx_http_proxy_redirect_follow.patch

###############################################################################

use warnings;
use strict;

use Test::More;

BEGIN { use FindBin; chdir($FindBin::Bin); }

use lib '../tests/lib';
use Test::Nginx;

###############################################################################

select STDERR; $| = 1;
select STDOUT; $| = 1;

my $t = Test::Nginx->new()->has(qw/http proxy cache/)->plan(3)
	->write_file_expand('nginx.conf', <<'EOF');

%%TEST_GLOBALS%%

master_process off;
daemon         off;

events {
}

http {
    %%TEST_GLOBALS_HTTP%%

    server {
        listen       127.0.0.1:8080;
        server_name  localhost;

        location /301 {
            proxy_pass    http://127.0.0.1:8081;
            proxy_redirect_follow 301;
        }

        location /302 {
            proxy_pass    http://127.0.0.1:8081;
            proxy_redirect_follow 301 302;
        }

        location /off {
            proxy_pass    http://127.0.0.1:8081;
            proxy_redirect_follow off;
        }

    }
    server {
        listen       127.0.0.1:8081;
        server_name  localhost;

        location / {
            return 200 "test";
        }

        location /302 {
            rewrite .* /302_real redirect;
        }

        location /301 {
            rewrite .* /301_real permanent;
        }

        location /off {
            rewrite .* /off_real redirect;
        }

        location /301_real {
            return 200 "301 pass";
        }

        location /302_real {
            return 200 "302 pass";
        }

        location /off_real {
            return 200 "off failed";
        }
    }
}

EOF

$t->run();

###############################################################################

like(http_get('/301'), qr/301 pass/, 'proxy redicet follow 301 request');
like(http_get('/302'), qr/302 pass/, 'proxy redicet follow 302 request');
like(http_get('/off'), qr/302 Moved Temporarily/, 'proxy redicet follow off request');


###############################################################################
