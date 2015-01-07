use strict;
use warnings;

use lib "lib";
use lib "t/testapp/lib";

use Test::More;
use Plack::Builder;
use Plack::Test;
use HTTP::Request;
use HTTP::Request::Common;

$ENV{DANCER_CONFDIR} = 't/testapp';
$ENV{DANCER_ENVIRONMENT} = 'auto_online';
require t::testapp::lib::Site;
require t::testapp::lib::TestSupport;
require Strehler::Admin;
require Strehler::API;

TestSupport::reset_database();

my $admin_app = Strehler::Admin->to_app;
my $site_app = Site->to_app;

#Test for empty contents
test_psgi $site_app, sub {
    my $cb = shift;
    my $site = "http://localhost";
    my $r = $cb->(GET "/ex/slug/not-existent");
    is($r->code, 404, "404 returned when bad slug called");
    $r = $cb->(GET "/ex/list/dummy");
    is($r->code, 200, "list works correctly with an empty list");
    $r = $cb->(GET "/ex/mypage");
    is($r->code, 200, "composite page works correctly with empty contents");
    $r = $cb->(GET "/exref/slug/not-existent");
    is($r->code, 404, "404 returned when bad slug called (parameters as hash)");
    $r = $cb->(GET "/exref/list/dummy");
    is($r->code, 200, "list works correctly with an empty list (parameters as hash)");
    $r = $cb->(GET "/exref/mypage");
    is($r->code, 200, "composite page works correctly with empty contents (parameters as hash)");
};

#Test contents
my $slug = undef;
test_psgi $admin_app, sub {
    my $cb = shift;
    my $site = "http://localhost";
    my $cat1_id = TestSupport::create_category($cb, 'dummy');
    my $cat2_id = TestSupport::create_category($cb, 'upper');
    my $cat3_id = TestSupport::create_category($cb, 'lower');
    TestSupport::create_article($cb, '1', $cat1_id, undef);
    TestSupport::create_article($cb, '2', $cat2_id, undef);
    TestSupport::create_article($cb, '3', $cat3_id, undef);
    my $articles = Strehler::Element::Article->get_list({ext => 1, category => 'dummy'});
    $slug = $articles->{'to_view'}->[0]->{'slug'};
};
test_psgi $site_app, sub {
    my $cb = shift;
    my $site = "http://localhost";
    my $res = $cb->(GET "/ex/slug/" . $slug);
    is($res->code, 200, "200 returned when good slug called");
    $res = $cb->(GET "/ex/list/dummy");
    is($res->code, 200, "list works correctly with contents");
    $res = $cb->(GET "/ex/mypage");
    is($res->code, 200, "composite page works correctly with contents");
    $res = $cb->(GET "/exref/slug/" . $slug);
    is($res->code, 200, "200 returned when good slug called (parameters as hash)");
    $res = $cb->(GET "/exref/list/dummy");
    is($res->code, 200, "list works correctly with contents (parameters as hash)");
    $res = $cb->(GET "/exref/mypage");
    is($res->code, 200, "composite page works correctly with contents (parameters as hash)");
};

done_testing;
