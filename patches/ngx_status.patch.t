#!/usr/bin/perl

# (C) Kirill A. Korinskiy

# Tests for ngx_status patch.

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

my $t = Test::Nginx->new()->has(qw/http proxy cache/)->plan(8)
	->write_file_expand('nginx.conf', <<'EOF');

%%TEST_GLOBALS%%

master_process off;
daemon         off;

events {
}

http {
    %%TEST_GLOBALS_HTTP%%

    proxy_cache_path   %%TESTDIR%%/cache  levels=1:2
                       keys_zone=NAME:10m;

    server {
        listen       127.0.0.1:8080;
        server_name  localhost;

        location / {
            proxy_pass    http://127.0.0.1:8081;

            proxy_cache   NAME;

            proxy_cache_valid   200 302  1s;
            proxy_cache_valid   301      1d;
            proxy_cache_valid   any      1m;

            proxy_cache_bypass   $arg_skip;

            proxy_cache_min_uses  1;

            proxy_cache_use_stale  error timeout invalid_header http_500
                                   http_404;
        }

        location = /status.txt {
            status_txt 0;
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

$t->write_file('t.html', 'SEE-THIS');
$t->write_file('t2.html', 'SEE-THIS');
$t->write_file('empty.html', '');
$t->run();

###############################################################################

http_get('/t.html');

http_get('/empty.html');
http_get('/empty.html');

$t->write_file('t.html', 'NOOP');
unlink $t->testdir() . '/empty.html';

sleep(2);

http_get('/t.html');

http_get('/t.html?skip=true');

http_head('/t2.html');
http_head('/t2.html');
http_head('/t2.html');

http_get('/empty.html');

my $status = http_get('/status.txt');

like($status, qr/Proxy cache missing: 3/, 'count of missing');
like($status, qr/Proxy cache by pass: 1/, 'count of by pass');
like($status, qr/Proxy cache expired: 2/, 'count of expired');
like($status, qr/Proxy cache stale: 0/, 'count of stale');
like($status, qr/Proxy cache updating: 0/, 'count of updating');
like($status, qr/Proxy cache hit: 3/, 'count of hit');
like($status, qr/Proxy cache scarce: 0/, 'count of scarce');
like($status, qr/Request for server 127.0.0.1:8081: 6/, 'count of upstream request');

###############################################################################
