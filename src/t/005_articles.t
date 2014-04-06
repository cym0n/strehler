use strict;
use warnings;

use Test::More;
use Test::TCP;
use LWP::UserAgent;
use FindBin;
use Data::Dumper;

use t::testapp::lib::Site;

Site::reset_database();

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $site = "http://127.0.0.1:$port";
        my $ua = LWP::UserAgent->new;
        my $res;
        $ua->cookie_jar({file => "cookies.txt"});
        push @{ $ua->requests_redirectable }, 'POST';
        $res = $ua->post($site . "/admin/login", { user => 'admin', password => 'admin' });

        #Dummy category created for test purpose
        $res = $ua->post($site . "/admin/category/add",
                         { 'category' => 'prova',
                           'parent' => '',
                           'tags-all' => 'tag1,tag2,tag3',
                           'default-all' => 'tag2',
                           'tags-article' => '',
                           'default-article' => '',
                           'tags-image' => '',
                           'default-image' => '' });
        my $cat = Strehler::Meta::Category->new({ category => 'prova' });
        my $cat_id = $cat->get_attr('id');

        #LIST
        $res = $ua->get($site . "/admin/article/list");
        is($res->code, 200, "Articles page correctly accessed");
        $res = $ua->get($site . "/admin/article/list?order-by=contents.title&order=asc");
        is($res->code, 200, "Articles page correctly accessed (order parameters added)");

        #ADD        
        $res = $ua->post($site . "/admin/article/add",
                         { 'image' => undef,
                           'category' => $cat_id,
                           'subcategory' => undef,
                           'tags' => 'tag1',
                           'display_order' => 14,
                           'publish_date' => '12/03/2014',
                           'title_it' => 'Automatic test - title - IT',
                           'text_it' => 'Automatic test - body - IT',
                           'title_en' => 'Automatic test - title - EN',
                           'text_en' => 'Automatic test - body - EN'
                          });
        is($res->code, 200, "New article successfully posted");
        my $articles = Strehler::Element::Article->get_list();
        my $article = $articles->{'to_view'}->[0];
        my $article_id = $article->{'id'};
        my $article_object = Strehler::Element::Article->new($article_id);
        ok($article_object->exists(), "Article correctly inserted");

        #TURN ON
        $res = $ua->get($site . "/admin/article/turnon/$article_id");
        $article_object = Strehler::Element::Article->new($article_id);
        ok($article_object->get_attr('published'), "Article correctly published");

        #LAST CHAPTER
        $ua->default_header('X-Requested-With' => "XMLHttpRequest");
        $res = $ua->get($site . "/admin/article/lastchapter/$cat_id");
        is($res->content, 15, "Last chapter function works");

        #TAGS
        my $tags_string = '<input type="checkbox" name="configured-tag" value="tag1" checked><span>tag1</span>';
        $res = $ua->get($site . "/admin/article/tagform/$article_id");
        like($res->content, qr/$tags_string/, "Tags checkbox correctly generated");

        #DELETE
        $ua->default_header('X-Requested-With' => undef);
        $res = $ua->post($site . "/admin/article/delete/$article_id");
        $article_object = Strehler::Element::Article->new($article_id);
        ok(! $article_object->exists(), "Article correctly deleted");

    },
    server => sub {
        use Dancer2;
        my $port = shift;
        Dancer2->runner->server->port($port);
        start;
    },
);

done_testing;
