#!/usr/bin/perl

# (C) Kirill A. Korinskiy

# Tests for ngx_http_variable_args_from_post patch.

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

my $t = Test::Nginx->new()->has(qw/http proxy/)->plan(8)
	->write_file_expand('nginx.conf', <<'EOF');

%%TEST_GLOBALS%%

master_process off;
daemon         off;

events {
}

http {
    %%TEST_GLOBALS_HTTP%%

    map  $uri $port {
        /post_off   8081;
        /post_on    8082;
        /post_first 8083;
        /post_last  8084;

        default     8085;
    }

    server {
        listen       127.0.0.1:8080;
        server_name  localhost;

        location / {
            proxy_pass http://127.0.0.1:$port;
        }
    }

    server {
        listen       127.0.0.1:8081;
        server_name  localhost;

        use_args_from_post off;
        return 200 "xxx${arg_test}yyy";
    }

    server {
        listen       127.0.0.1:8082;
        server_name  localhost;

        use_args_from_post on;
        return 200 "xxx${arg_test}yyy";
    }

    server {
        listen       127.0.0.1:8083;
        server_name  localhost;

        use_args_from_post first;
        return 200 "xxx${arg_test}yyy";
    }

    server {
        listen       127.0.0.1:8084;
        server_name  localhost;

        use_args_from_post last;
        return 200 "xxx${arg_test}yyy";
    }

    server {
        listen       127.0.0.1:8085;
        server_name  localhost;

        return 404;
    }
}

EOF

$t->run();

###############################################################################

like(http_post('/post_off', 'test=test'), qr/^xxxyyy$/m, 'post_off only POST');
like(http_post('/post_off?test=test2', 'test=test1'), qr/^xxxtest2yyy$/m, 'post_off with GET');

like(http_post('/post_on', 'test=test'), qr/^xxxtestyyy$/m, 'post_on only POST');
like(http_post('/post_on?test=test2', 'test=test1'), qr/^xxxtest2yyy$/m, 'post_on with GET');

like(http_post('/post_first', 'test=test'), qr/^xxxtestyyy$/m, 'post_firstr only POST');
like(http_post('/post_first?test=test2', 'test=test1'), qr/^xxxtest1yyy$/m, 'post_first with GET');

like(http_post('/post_last', 'test=test'), qr/^xxxtestyyy$/m, 'post_last only POST');
like(http_post('/post_last?test=test2', 'test=test1'), qr/^xxxtest2yyy$/m, 'post_last with GET');

###############################################################################

sub http_post {
	my ($url, $data, %extra) = @_;
        my $len = length($data);
	return http(<<EOF, %extra);
POST $url HTTP/1.1
Host: localhost
Content-Length: $len
Connection: close

$data
EOF
}

###############################################################################
