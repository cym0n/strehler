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
require t::testapp::lib::TestSupport;

TestSupport::reset_database();

my $app = Strehler::Admin->to_app;

test_psgi $app, sub {
    my $cb = shift;
    my $site = "http://localhost";

    #LIST
    my $r = $cb->( GET '/admin/category/list' );
    is($r->code, 200, "Category page correctly accessed");
    
    #ADD
    $r = $cb->( GET '/admin/category/add' );
    my $entity_string = '<div class="alert alert-info">.*All.*</div>';
    like($r->content, qr/$entity_string/s, "All present in category add page for tags");
    foreach my $t ('article', 'image', 'dummy', 'foo')
    {
        my $entity_string = '<div class="alert alert-info">.*Per ' . $t . '.*</div>';
        like($r->content, qr/$entity_string/s, "$t present in category add page for tags");
    }
    $entity_string = '<div class="alert alert-info">.*Per puppet.*</div>';
    unlike($r->content, qr/$entity_string/s, "Puppet not present in category add page for tags");

    $r = $cb->( POST '/admin/category/add', 
                    [ 'category' => 'prova',
                      'parent' => '',
                      'tags-all' => 'tag1,tag2,tag3',
                      'default-all' => 'tag2',
                      'tags-article' => '',
                      'default-article' => '',
                      'tags-image' => '',
                      'default-image' => '' ] );
    my $cat = Strehler::Meta::Category->new({ category => 'prova' });
    my $cat_id = $cat->get_attr('id');
    ok($cat->exists(), "Category inserted");  

    $r = $cb->( POST '/admin/category/add', 
                    [ 'category' => 'prova2',
                      'parent' => '',
                      'tags-all' => '',
                      'default-all' => '',
                      'tags-article' => 'tagart1,tagart2,tagart3',
                      'default-article' => '',
                      'tags-image' => '',
                      'default-image' => '' ] );
    my $cat2 = Strehler::Meta::Category->new({ category => 'prova2' });
    my $cat2_id = $cat2->get_attr('id');

    $r = $cb->( POST '/admin/category/add', 
                    [ 'category' => 'child',
                      'parent' => $cat_id,
                      'tags-all' => '',
                      'default-all' => '',
                      'tags-article' => 'tagart1,tagart2,tagart3',
                      'default-article' => '',
                      'tags-image' => '',
                      'default-image' => '' ]);
    my $cat3 = Strehler::Meta::Category->explode_name("prova/child");
    ok($cat3->exists(), "Child category inserted and retrieved");
    my $cat3_id = $cat3->get_attr('id');

    TestSupport::create_article($cb, undef, $cat3_id, undef);

    #SELECT
    my $select_string = '<option value="' . $cat->get_attr('id') . '">prova</option>';
    my $req = HTTP::Request->new(GET => $site . '/admin/category/select');
    $req->header('X-Requested-With' => 'XMLHttpRequest');
    $r = $cb->($req); 
    like($r->content, qr/$select_string/, "Categories select combo correctly generated");

    #DELETE
    $r = $cb->(GET "/admin/category/delete/$cat_id");
    like($r->content, qr/has subcategories/, "Deletion forbidden for subcategory");
    $r = $cb->(GET "/admin/category/delete/$cat3_id");
    like($r->content, qr/is not empty/, "Deletion forbidden for contents");
    $r = $cb->(GET "/admin/category/delete/$cat2_id");
    is($r->code, 200, "Category deletion answers (GET) OK");
    like($r->content, qr/Delete $cat2_id of category/, "Deletion allowed, confirm requested");
    $r = $cb->(POST "/admin/category/delete/$cat2_id");
    my $cat_again = Strehler::Meta::Category->new({ category => 'prova2' });
    ok(! $cat_again->exists(), "Category deleted");
};
done_testing;
