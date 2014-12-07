use strict;
use warnings;

use Test::More;
use Test::TCP;
use LWP::UserAgent;
use FindBin;
use Data::Dumper;

$ENV{DANCER_CONFDIR} = 't/testapp';
require t::testapp::lib::Site;

Site::reset_database();

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $site = "http://127.0.0.1:$port";
        my $ua = LWP::UserAgent->new;
        my $res;
        $ua->cookie_jar({file => "cookies.txt"});
        $res = $ua->get($site . "/ex/slug/not-existent");
        is($res->code, 404, "404 returned when bad slug called");
        $res = $ua->get($site . "/ex/list/dummy");
        is($res->code, 200, "list works correctly with an empty list");
        $res = $ua->get($site . "/ex/mypage");
        is($res->code, 200, "composite page works correctly with empty contents");
        $res = $ua->get($site . "/exref/slug/not-existent");
        is($res->code, 404, "404 returned when bad slug called (parameters as hash)");
        $res = $ua->get($site . "/exref/list/dummy");
        is($res->code, 200, "list works correctly with an empty list (parameters as hash)");
        $res = $ua->get($site . "/exref/mypage");
        is($res->code, 200, "composite page works correctly with empty contents (parameters as hash)");
        $ua->post($site . "/admin/login", { user => 'admin', password => 'admin' });

        $res = $ua->post($site . "/admin/category/add",
                         { 'category' => 'dummy',
                           'parent' => '',
                           'tags-all' => '',
                           'default-all' => '',
                           'tags-article' => '',
                           'default-article' => '',
                           'tags-image' => '',
                           'default-image' => '' });
        $res = $ua->post($site . "/admin/category/add",
                         { 'category' => 'upper',
                           'parent' => '',
                           'tags-all' => '',
                           'default-all' => '',
                           'tags-article' => '',
                           'default-article' => '',
                           'tags-image' => '',
                           'default-image' => '' });
        $res = $ua->post($site . "/admin/category/add",
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
        $res = $ua->post($site . "/admin/article/add",
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
        $res = $ua->post($site . "/admin/article/add",
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
        $res = $ua->post($site . "/admin/article/add",
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
        my $articles = Strehler::Element::Article->get_list({ext => 1});
        my $slug;
        foreach my $a (@{$articles->{'to_view'}})
        {
           $res = $ua->get($site . "/admin/article/turnon/" . $a->{'id'});
           $slug = $a->{'slug'};
        }
        $res = $ua->get($site . "/ex/slug/" . $slug);
        is($res->code, 200, "200 returned when good slug called");
        $res = $ua->get($site . "/ex/list/dummy");
        is($res->code, 200, "list works correctly with contents");
        $res = $ua->get($site . "/ex/mypage");
        is($res->code, 200, "composite page works correctly with contents");
        $res = $ua->get($site . "/exref/slug/" . $slug);
        is($res->code, 200, "200 returned when good slug called (parameters as hash)");
        $res = $ua->get($site . "/exref/list/dummy");
        is($res->code, 200, "list works correctly with contents (parameters as hash)");
        $res = $ua->get($site . "/exref/mypage");
        is($res->code, 200, "composite page works correctly with contents (parameters as hash)");
    },
    server => sub {
        use Dancer2;
        my $port = shift;
        Dancer2->runner->{'port'} = $port;
        start;
    },
);

done_testing;
