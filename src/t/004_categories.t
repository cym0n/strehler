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

local $ENV{DANCER_CONFDIR} = 't/testapp';
local $ENV{DANCER_ENVIRONMENT} = 'no_login';
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
        $entity_string = '<div class="alert alert-info">.*Per ' . $t . '.*</div>';
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
    $r = $cb->( POST '/admin/category/add', 
                    [ 'category' => 'childbis',
                      'parent' => '',
                      'tags-all' => '',
                      'default-all' => '',
                      'tags-article' => 'tagart1,tagart2,tagart3',
                      'default-article' => '',
                      'tags-image' => '',
                      'default-image' => '' ]);
    my $cat3bis = Strehler::Meta::Category->explode_name("childbis");
    my $cat3bis_id = $cat3bis->get_attr('id');

    $r = $cb->( POST '/admin/category/add', 
                    [ 'category' => 'subchild',
                      'parent' => $cat3_id,
                      'tags-all' => '',
                      'default-all' => '',
                      'tags-article' => 'tagart1,tagart2,tagart3',
                      'default-article' => '',
                      'tags-image' => '',
                      'default-image' => '' ]);
    my $cat4 = Strehler::Meta::Category->explode_name("prova/child/subchild");
    ok($cat4->exists(), "Third level category inserted and retrieved");
    my $cat4_id = $cat4->get_attr('id');

    $r = $cb->( POST '/admin/category/add', 
                    [ 'category' => 'prova3',
                      'parent' => '',
                      'tags-all' => '',
                      'default-all' => '',
                      'tags-article' => 'tagart1,tagart2,tagart3',
                      'default-article' => '',
                      'tags-image' => '',
                      'default-image' => '' ]);
    my $cat5 = Strehler::Meta::Category->explode_name("prova3");
    my $cat5_id = $cat5->get_attr('id');
    $r = $cb->( POST '/admin/category/add', 
                    [ 'category' => 'unluckychild',
                      'parent' => $cat5_id,
                      'tags-all' => '',
                      'default-all' => '',
                      'tags-article' => 'tagart1,tagart2,tagart3',
                      'default-article' => '',
                      'tags-image' => '',
                      'default-image' => '' ]);
    my $cat6 = Strehler::Meta::Category->explode_name("prova3/unluckychild");
    my $cat6_id = $cat6->get_attr('id');

    TestSupport::create_article($cb, undef, $cat3_id);
    TestSupport::create_article($cb, undef, $cat3bis_id);

    # prova[]/*child[3]/subchild[4]
    # childbis[3bis]
    # prova2[2]
    # prova3[5]/unluckychild[6]

    #SELECT
    my $select_string = '<option value="' . $cat->get_attr('id') . '">prova</option>';
    my $req = HTTP::Request->new(GET => $site . '/admin/category/select');
    $req->header('X-Requested-With' => 'XMLHttpRequest');
    $r = $cb->($req); 
    like($r->content, qr/$select_string/, "Categories select combo correctly generated");

    #DELETE
    $r = $cb->(POST "/admin/category/delete/$cat3bis_id");
    like($r->content, qr/is not empty/, "Deletion forbidden for contents");
    $r = $cb->(POST "/admin/category/delete-tree/$cat_id");
    like($r->content, qr/is not empty/, "Recursive deletion stopped for contents");
    my $cat4_again = Strehler::Meta::Category->explode_name('prova/child/subchild');
    my $cat3_again = Strehler::Meta::Category->explode_name('prova/child');
    my $cat_again = Strehler::Meta::Category->explode_name('prova');
    ok( (! $cat4_again->exists() && $cat3_again->exists() && $cat_again->exists()), "Recursive deletion stopped at the right level" );
    $r = $cb->(GET "/admin/category/delete/$cat2_id");
    is($r->code, 200, "Category deletion answers (GET) OK");
    like($r->content, qr/Delete $cat2_id of category/, "Deletion allowed, confirm requested");
    $r = $cb->(POST "/admin/category/delete/$cat2_id");
    my $cat2_again = Strehler::Meta::Category->explode_name('prova2');
    ok(! $cat2_again->exists(), "Category deleted");
    $r = $cb->(POST "/admin/category/delete-tree/$cat5_id");
    my $cat5_again = Strehler::Meta::Category->explode_name('prova3');
    ok(! $cat5_again->exists(), "Category deleted with all its tree");
};
done_testing;

1;
