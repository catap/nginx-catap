#!/usr/bin/perl

# (C) Kirill A. Korinskiy

# Tests for ngx_http_ssi_for patch.

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

my $t = Test::Nginx->new()->has(qw/http proxy/)->plan(11)
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

$t->write_file('test1.html',
	'X<!--# for data="arg_test" var="i" sep=" " -->Y<!--# echo var="i" -->Y<!--# endfor -->X');
$t->write_file('test2.html',
        'X<!--# for data="arg_test" sep="+" --><!--# echo var="_" -->,<!--# lastfor --><!--# echo var="_" --><!--# endfor -->X');
$t->run();

###############################################################################

like(http_get('/test1.html'), qr/^XX$/m, '');

like(http_get('/test1.html?test=test1'), qr/^XYtest1YX$/m, '');
like(http_get('/test1.html?test=test1 '), qr/^XYtest1YX$/m, '');

like(http_get('/test1.html?test= test1'), qr/^XYtest1YX$/m, '');
like(http_get('/test1.html?test= test1 '), qr/^XYtest1YX$/m, '');

like(http_get('/test1.html?test=    test1    '), qr/^XYtest1YX$/m, '');

like(http_get('/test1.html?test=test1 test2'), qr/^XYtest1YYtest2YX$/m, '');
like(http_get('/test1.html?test=test1 test2 '), qr/^XYtest1YYtest2YX$/m, '');

like(http_get('/test1.html?test= test1 test2 '), qr/^XYtest1YYtest2YX$/m, '');
like(http_get('/test1.html?test=    test1 test2    '), qr/^XYtest1YYtest2YX$/m, '');

like(http_get('/test2.html?test=1+2+3+4 '), qr/^X1,2,3,4X$/m, '');

###############################################################################
