#!/usr/bin/perl

# (C) Kirill A. Korinskiy

# Tests for generic-variables-crc32-and-md5 patch.

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

my $t = Test::Nginx->new()->has(qw/http proxy/)->plan(2) #proxy for md5
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
            add_header Set-Cookie "md5=$md5_uri; path=/";
            add_header Set-Cookie "crc=$crc32_uri; path=/";
        }
    }
}

EOF

$t->write_file('t.html', 'SEE-THIS');
$t->run();

###############################################################################

my $res = http_get('/t.html');

like($res, qr/md5=F32ADA2461603FB0F04350BFE95D0E5B/, 'md5 variable');
like($res, qr/crc=73E66F40/, 'crc32 variable');

###############################################################################
