#!/usr/bin/perl

# (C) Kirill A. Korinskiy

# Tests for ngx_http_variable_urlencode_and_urldecode patch.

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

my $t = Test::Nginx->new()->has(qw/http/)->plan(2)
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

        location /encode {
            return 200 "$urlencode_args";
        }

        location /decode {
            return 200 "$urldecode_args";
        }
    }
}

EOF

$t->run();

###############################################################################

like(http_get('/encode?тест'), qr/%d1%82%d0%b5%d1%81%d1%82/, 'encode variable');
like(http_get('/decode?%d1%82%d0%b5%d1%81%d1%82'), qr/тест/, 'decode variable');

###############################################################################
