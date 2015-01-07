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
    my $r = $cb->(GET '/admin/article/add');
    like($r->content, qr/No category in the system/, "Article add blocked because no category");

    ok(Strehler::Element::Article->slugged(), "[configuration] Article has slug");


    my $cat_id = TestSupport::create_category($cb, 'prova');

    $r = $cb->(POST "/admin/article/add",
                [ 'image' => undef,
                  'category' => $cat_id,
                  'subcategory' => undef,
                  'tags' => 'tag1',
                  'display_order' => 14,
                  'publish_date' => '12/03/2014',
                  'title_it' => 'Automatic test - title - IT',
                  'text_it' => 'Automatic test - body - IT',
                  'title_en' => 'Automatic test - title - EN',
                  'text_en' => 'Automatic test - body - EN',
                  'strehl-action' => 'submit-go' 
                ]);
   is($r->code, 302, "Article submitted, navigation redirected to list (submit-go)");

   #LIST
   $r = $cb->(GET '/admin/article/list');
   is($r->code, 200, "Articles page correctly accessed");
   $r = $cb->(GET '/admin/article/list?order-by=contents.title&order=asc');
   is($r->code, 200, "Articles page correctly accessed (order parameters added)");
   my @ids = TestSupport::list_reader($r->content);
   my $article_id = $ids[0];

   #EDIT
   my $article_object = Strehler::Element::Article->new($article_id);
   ok($article_object->exists(), "Article correctly inserted");
   is($article_object->get_attr_multilang('slug', 'it'), $article_id . '-automatic-test-title-it', "Slug correctly created"); 
   $r = $cb->(POST "/admin/article/edit/$article_id",
                [ 'image' => undef,
                  'category' => $cat_id,
                  'subcategory' => undef,
                  'tags' => 'tag1',
                  'display_order' => 14,
                  'publish_date' => '12/03/2014',
                  'title_it' => 'Automatic test - title - IT',
                  'text_it' => 'Automatic test - body changed - IT',
                  'title_en' => 'Automatic test - title - EN',
                  'text_en' => 'Automatic test - body changed - EN',
                  'strehl-action' => 'submit-continue' 
                ]);
   is($r->code, 200, "Content changed, navigation still on edit page (submit-continue)");

   #TURN ON
   $r = $cb->(GET "/admin/article/turnon/$article_id");
   $article_object = Strehler::Element::Article->new($article_id);
   ok($article_object->get_attr('published'), "Article correctly published");

   #LAST CHAPTER
   my $req = HTTP::Request->new(GET => $site . "/admin/article/lastchapter/$cat_id");
   $req->header('X-Requested-With' => 'XMLHttpRequest');
   $r = $cb->($req); 
   is($r->content, 15, "Last chapter function works");

   #DELETE
   $r = $cb->(POST $site . "/admin/article/delete/$article_id");
   $article_object = Strehler::Element::Article->new($article_id);
   ok(! $article_object->exists(), "Article correctly deleted");

   #LIST FILTERED BY LANGUAGE
   #Three contents for it, just one for en
   TestSupport::create_article($cb, '1', $cat_id, undef, { publish_date => '10/10/2014', title_en => undef, text_en => undef });
   TestSupport::create_article($cb, '2', $cat_id, undef, { publish_date => '10/10/2014', title_en => undef, text_en => undef });
   TestSupport::create_article($cb, '3', $cat_id);

   $r = $cb->(GET '/admin/article/list?language=it');
   @ids = TestSupport::list_reader($r->content);
   is($#ids, 2, "Three italian contents listed"); 
   #Just a SQLite issue: id could be considered an ambiguous field. (No problems on MySQL)
   $r = $cb->(GET '/admin/article/list?language=it&order-by=id');
   @ids = TestSupport::list_reader($r->content);
   is($#ids, 2, "Three italian contents listed, ordered by id"); 
   $r = $cb->(GET '/admin/article/list?language=en');
   @ids = TestSupport::list_reader($r->content);
   is($#ids, 0, "One english content listed");
    

};
done_testing;
