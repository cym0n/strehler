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

my $app = Strehler::Admin->to_app;
my $jar = HTTP::Cookies->new;

sub keep_logged
{
    my $cb = shift;
    my %request_params = @_;
    my $req = HTTP::Request->new(%request_params);
    $jar->add_cookie_header($req);
    my $r = $cb->($req); 
    $jar->extract_cookies($r);
    return $r;
}


test_psgi $app, sub {
    my $cb = shift;
    my $site = "http://localhost";
    my $r = $cb->( POST '/admin/login', [ user => 'editor', password => 'editor' ]);
    $jar->extract_cookies($r);
    my $req = HTTP::Request->new(GET => $site . '/admin');
    $jar->add_cookie_header($req);
    $r = $cb->($req); 
    like($r->decoded_content, qr/<b class="icon-user"><\/b>.*editor/, "Login as editor");
    $r = keep_logged($cb, GET => $site . '/admin/article/list');
    is($r->code, 200, "Editor can access articles");
    $r = keep_logged($cb, GET => $site . '/admin/category/list');
    is($r->code, 403, "Editor cannot access categories");
};

done_testing;
