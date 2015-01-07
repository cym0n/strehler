use strict;
use warnings;

use lib "lib";
use lib "t/testapp/lib";

use Test::More;
use Plack::Builder;
use Plack::Test;
use HTTP::Request;
use HTTP::Request::Common;
use Data::Dumper;

$ENV{DANCER_CONFDIR} = 't/testapp';
$ENV{DANCER_ENVIRONMENT} = 'auto_online';
require Strehler::Admin;
require t::testapp::lib::Site;
require t::testapp::lib::TestSupport;

TestSupport::reset_database();

my $admin_app = Strehler::Admin->to_app;

######## Create contents to use in the test

my $test_slug;

test_psgi $admin_app, sub {
    my $cb = shift;
    my $site = "http://localhost";
    my $cat_id = TestSupport::create_category($cb, 'prova');
    TestSupport::create_article($cb, 'one', $cat_id, undef, { display_order => 14, 'publish_date' => '12/03/2014'});
    my $art = Strehler::Element::Article->get_last_by_order('prova', 'it');
    $test_slug = $art->get_attr_multilang('slug', 'it');
    TestSupport::create_article($cb, 'two', $cat_id, undef, { display_order => 5, 'publish_date' => '12/05/2014'});
    TestSupport::create_article($cb, 'three', $cat_id, undef, { display_order => 20, 'publish_date' => '12/01/2014'});
};

######## Tests

# TEST CASE SCHEMA:
#
#            (display_order axis)
#                   TWO
#                    |
#                    |
#                    V
#        THREE ---> ONE ---> TWO (publish_date axis)
#                    | 
#                    |  
#                    V
#                  THREE

my $site_app = Site->to_app;
test_psgi $site_app, sub {
    my $cb = shift;
    my $r = $cb->(GET '/it/get-last-by-order/prova');
    is($r->content, 'Automatic test three - title - IT', "Get Last By Orded - IT");
    $r = $cb->(GET '/it/get-first-by-order/prova');        
    is($r->content, 'Automatic test two - title - IT', "Get First By Orded - IT");
    $r = $cb->(GET '/en/get-first-by-order/prova');        
    is($r->content, 'Automatic test two - title - EN', "Get First By Orded - EN");
    $r = $cb->(GET '/en/get-first-by-date/prova');        
    is($r->content, 'Automatic test three - title - EN', "Get First By Date - EN");
    $r = $cb->(GET '/it/get-last-by-date/prova');        
    is($r->content, 'Automatic test two - title - IT', "Get Last By Date - IT");
    $r = $cb->(GET "/it/slug/$test_slug");        
    is($r->content, 'Automatic test one - title - IT', "Get by Slug - IT");
};


done_testing;
