#!/usr/bin/perl

# (C) Kirill A. Korinskiy

# Tests for ngx_http_ssi_inheritance_args patch.

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

my $t = Test::Nginx->new()->has(qw/http proxy/)->plan(1)
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

        location / {
            ssi on;
        }
    }
}

EOF

$t->write_file('t.html',
	'X<!--#include file="/args.html" -->X');
$t->write_file('args.html',
	'X<!--#echo var="arg_test" -->X');
+$t->run();

###############################################################################

like(http_get('/t.html?test=test'), qr/^XXtestXX$/m, 'args inheritance');

###############################################################################
