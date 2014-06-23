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

        #Dummy categories created for test purpose
        $res = $ua->post($site . "/admin/category/add",
                         { 'category' => 'prova',
                           'parent' => undef,
                           'tags-all' => '',
                           'default-all' => '',
                           'tags-article' => '',
                           'default-article' => '',
                           'tags-image' => '',
                           'default-image' => '' });
        my $ancestor_cat = Strehler::Meta::Category->explode_name('prova');
        my $ancestor_cat_id = $ancestor_cat->get_attr('id');

        $res = $ua->post($site . "/admin/category/add",
                         { 'category' => 'foo',
                           'parent' => $ancestor_cat_id,
                           'tags-all' => '',
                           'default-all' => '',
                           'tags-article' => '',
                           'default-article' => '',
                           'tags-image' => '',
                           'default-image' => '' });

        my $child_cat = Strehler::Meta::Category->explode_name('prova/foo');;
        my $child_cat_id = $child_cat->get_attr('id');

        #Dummy articles created for test purpose
        $res = $ua->post($site . "/admin/article/add",
                         { 'image' => undef,
                           'category' => $ancestor_cat_id,
                           'subcategory' => undef,
                           'tags' => '',
                           'display_order' => 1,
                           'publish_date' => '',
                           'title_it' => 'Automatic test 1 - title - IT',
                           'text_it' => 'Automatic test 1 - body - IT',
                           'title_en' => 'Automatic test 1 - title - EN',
                           'text_en' => 'Automatic test 1 - body - EN'
                          });
        $res = $ua->post($site . "/admin/article/add",
                         { 'image' => undef,
                           'category' => $ancestor_cat_id,
                           'subcategory' => $child_cat_id,
                           'tags' => '',
                           'display_order' => 2,
                           'publish_date' => '',
                           'title_it' => 'Automatic test 2 - title - IT',
                           'text_it' => 'Automatic test 2 - body - IT',
                           'title_en' => 'Automatic test 2 - title - EN',
                           'text_en' => 'Automatic test 2 - body - EN'
                          });
        $res = $ua->get($site . "/api/v1/articles/");
        is($res->code, 200, "Articles api correctly called");
    },
    server => sub {
        use Dancer2;
        my $port = shift;
        if($Dancer2::VERSION < 0.14)
        {
            Dancer2->runner->server->port($port);
        }
        else
        {
            Dancer2->runner->{'port'} = $port;
        }
        start;
    },
);

done_testing;
