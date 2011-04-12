#!/usr/bin/perl

# (C) Kirill A. Korinskiy

# Tests for ngx_http_map patch.

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

my $t = Test::Nginx->new()->has(qw/http proxy/)->plan(3)
	->write_file_expand('nginx.conf', <<'EOF');

%%TEST_GLOBALS%%

master_process off;
daemon         off;

events {
}

http {
    %%TEST_GLOBALS_HTTP%%

    map $arg_key $val1 $val2{
        default     "1" "2";

        test        "123" "245";
        var         "$arg_var1" "$arg_var2";
    }

    server {
        listen       127.0.0.1:8080;
        server_name  localhost;

        location / {
            return 200 "$val1 $val2";
        }
    }
}

EOF

$t->run();

###############################################################################

like(http_get('/?key=none'), qr/1 2/, 'map dfault value');
like(http_get('/?key=test'), qr/123 245/, 'map value');
like(http_get('/?key=var&var1=test1&var2=test2'), qr/test1 test2/, 'map variable value');

###############################################################################
