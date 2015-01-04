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
$ENV{DANCER_ENVIRONMENT} = 'no_login';
require Strehler::Admin;
require t::testapp::lib::Site;
require t::testapp::lib::TestSupport;
require t::testapp::lib::Site::Dummy;

TestSupport::reset_database();

my $admin_app = Strehler::Admin->to_app;
my $site_app = Site->to_app;

my $dummy_object;

test_psgi $admin_app, sub {
    my $cb = shift;
    my $site = "http://localhost";

    my $r = $cb->(GET '/admin/dummy/add');
    like($r->content, qr/No category in the system/, "Dummy add blocked because no category");

    $r = $cb->(GET '/admin/puppet/add');
    like($r->content, qr/Submit/, "Puppet (not categorized entity) add allowed also with no category");

    my $cat_id = TestSupport::create_category($cb, 'prova');

    #LIST
    $r = $cb->(GET "/admin/dummy/list");
    is($r->code, 200, "Dummy list page correctly accessed");

    #ADD
    $r = $cb->(POST '/admin/dummy/add',
                         { 'category' => $cat_id,
                           'subcategory' => undef,
                           'tags' => 'tag1',
                           'text' => 'A dumb text',
                          });
    my $dummies = Site::Dummy->get_list();
    my $dummy = $dummies->{'to_view'}->[0];
    my $dummy_id = $dummy->{'id'};
    $dummy_object = Site::Dummy->new($dummy_id);
    ok($dummy_object->exists(), "Dummy object correctly inserted");
    is($dummy_object->get_attr('slug'), $dummy_id . '-a-dumb-text', "Slug correctly created");
};
test_psgi $site_app, sub {
    my $cb = shift;
    my $site = "http://localhost";
    #CALL BY SLUG
    my $r = $cb->(GET '/dummyslug/' . $dummy_object->get_attr('slug'));        
    is($r->content, $dummy_object->get_attr('id'), "Get by Slug on dummy");
};
test_psgi $admin_app, sub {
    my $cb = shift;
    my $site = "http://localhost";
    my $dummy_id = $dummy_object->get_attr('id');
    my $r = $cb->(POST "/admin/dummy/delete/$dummy_id");
    $dummy_object = Site::Dummy->new($dummy_id);
    ok(! $dummy_object->exists(), "Dummy object correctly deleted");
};
done_testing;

