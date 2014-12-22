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

    my $res = $cb->(POST "/admin/category/add",
                         { 'category' => 'dummy',
                           'parent' => '',
                           'tags-all' => '',
                           'default-all' => '',
                           'tags-article' => '',
                           'default-article' => '',
                           'tags-image' => '',
                           'default-image' => '' });
    $res = $cb->(POST "/admin/category/add",
                         { 'category' => 'upper',
                           'parent' => '',
                           'tags-all' => '',
                           'default-all' => '',
                           'tags-article' => '',
                           'default-article' => '',
                           'tags-image' => '',
                           'default-image' => '' });
    $res = $cb->(POST "/admin/category/add",
                         { 'category' => 'lower',
                           'parent' => '',
                           'tags-all' => '',
                           'default-all' => '',
                           'tags-article' => '',
                           'default-article' => '',
                           'tags-image' => '',
                           'default-image' => '' });
    my $cat1 = Strehler::Meta::Category->explode_name('dummy');
    my $cat1_id = $cat1->get_attr('id');
    my $cat2 = Strehler::Meta::Category->explode_name('upper');
    my $cat2_id = $cat2->get_attr('id');
    my $cat3 = Strehler::Meta::Category->explode_name('lower');
    my $cat3_id = $cat3->get_attr('id');
    $res = $cb->(POST "/admin/article/add",
                         { 'image' => undef,
                           'category' => $cat1_id,
                           'subcategory' => undef,
                           'tags' => 'tag1',
                           'display_order' => 14,
                           'publish_date' => '12/03/2014',
                           'title_it' => 'Automatic test - title - IT',
                           'text_it' => 'Automatic test - body - IT',
                           'title_en' => 'Automatic test - title - EN',
                           'text_en' => 'Automatic test - body - EN'
                          });
    $res = $cb->(POST "/admin/article/add",
                         { 'image' => undef,
                           'category' => $cat2_id,
                           'subcategory' => undef,
                           'tags' => 'tag1',
                           'display_order' => 14,
                           'publish_date' => '12/03/2014',
                           'title_it' => 'Upper test - title - IT',
                           'text_it' => 'Upper test - body - IT',
                           'title_en' => 'Upper test - title - EN',
                           'text_en' => 'Upper test - body - EN'
                          });
    $res = $cb->(POST "/admin/article/add",
                         { 'image' => undef,
                           'category' => $cat3_id,
                           'subcategory' => undef,
                           'tags' => 'tag1',
                           'display_order' => 14,
                           'publish_date' => '12/03/2014',
                           'title_it' => 'Lower test - title - IT',
                           'text_it' => 'Lower test - body - IT',
                           'title_en' => 'Lower test - title - EN',
                           'text_en' => 'Lower test - body - EN'
                          });
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
