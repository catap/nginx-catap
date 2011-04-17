#!/usr/bin/perl

# (C) Kirill A. Korinskiy

# Tests for etag patch.

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

my $t = Test::Nginx->new()->has('http')->plan(2)
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
            if_modified_since before;
        }
    }
}

EOF

$t->run();

my $etag = write_test_file($t, 't');

###############################################################################

my $r = http_get_ims('/t', $etag);

like($r, qr!304!, '304 Not Modified');
like($r, qr!^ETag: $etag!m, 'etag');

###############################################################################

sub http_get_ims {
        my ($url, $ims) = @_;
        return http(<<EOF);
GET $url HTTP/1.0
Host: localhost
If-Match: $ims

EOF
}

sub write_test_file {
	my ($t, $path) = @_;

        $t->write_file($path, '');

        my @s = stat($t->{_testdir} . '/' . $path);

        return sprintf("%X-%X-%X", $s[7], $s[9], $s[1]);
}

###############################################################################
