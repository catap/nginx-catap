#!/usr/bin/perl

# (C) Kirill A. Korinskiy

# Tests for ngx_http_cache_multi_zone patch.

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

my $t = Test::Nginx->new()->has(qw/http proxy cache/)->plan(5)
	->write_file_expand('nginx.conf', <<'EOF');

%%TEST_GLOBALS%%

master_process off;
daemon         off;

events {
}

http {
    %%TEST_GLOBALS_HTTP%%

    proxy_cache_path   %%TESTDIR%%/cache1  levels=1:2
                       keys_zone=NAME1:10m;

    proxy_cache_path   %%TESTDIR%%/cache2  levels=1:2
                       keys_zone=NAME2:10m;

    server {
        listen       127.0.0.1:8080;
        server_name  localhost;

        location / {
            proxy_pass    http://127.0.0.1:8081;

            proxy_cache   NAME1 NAME2;

            proxy_cache_valid   200 302  1s;
            proxy_cache_valid   301      1d;
            proxy_cache_valid   any      1m;

            proxy_cache_min_uses  1;

            proxy_cache_use_stale  error timeout invalid_header http_500
                                   http_404;
        }
    }
    server {
        listen       127.0.0.1:8081;
        server_name  localhost;

        location / {
        }
    }
}

EOF

$t->run();
$t->write_file('t.html', 'SEE-THIS');
$t->write_file('t2.html', 'SEE-THIS');

###############################################################################

like(http_get('/t.html'), qr/SEE-THIS/, 'proxy request');

$t->write_file('t.html', 'NOOP');
like(http_get('/t.html'), qr/SEE-THIS/, 'proxy request cached');

unlike(http_head('/t2.html'), qr/SEE-THIS/, 'head request');
like(http_get('/t2.html'), qr/SEE-THIS/, 'get after head');
unlike(http_head('/t2.html'), qr/SEE-THIS/, 'head after get');


###############################################################################
