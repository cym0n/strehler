use strict;
use warnings;

use lib "lib";
use lib "t/testapp/lib";

use Test::More;
use Plack::Builder;
use Plack::Test;
use HTTP::Request;
use HTTP::Request::Common;
use HTTP::Cookies;

$ENV{DANCER_CONFDIR} = 't/testapp';
require Strehler::Admin;
require t::testapp::lib::TestSupport;

my $app = Strehler::Admin->to_app;

test_psgi $app, sub {
    my $cb = shift;
    my $site = "http://localhost";
    my $jar = HTTP::Cookies->new;
    my $r = undef;    
    ($r, $jar) = TestSupport::keep_logged($cb, $jar, POST $site . '/admin/login', [ user => 'editor', password => 'editor' ]);
    ($r, $jar) = TestSupport::keep_logged($cb, $jar, GET $site . '/admin');
    like($r->decoded_content, qr/<b class="icon-user"><\/b>.*editor/, "Login as editor");
    ($r, $jar) = TestSupport::keep_logged($cb, $jar, GET $site . '/admin/article/list');
    is($r->code, 200, "Editor can access articles");
    ($r, $jar) = TestSupport::keep_logged($cb, $jar, GET $site . '/admin/category/list');
    is($r->code, 403, "Editor cannot access categories");
};

done_testing;
