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

        #Dummy objects created for test purpose
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
        $res = $ua->post($site . "/admin/article/add",
                         { 'image' => undef,
                           'category' => $cat_id,
                           'subcategory' => undef,
                           'tags' => undef,
                           'display_order' => 14,
                           'publish_date' => '12/03/2014',
                           'title_it' => 'Automatic test one - title - IT',
                           'text_it' => 'Automatic test one - body - IT',
                           'title_en' => 'Automatic test one - title - EN',
                           'text_en' => 'Automatic test one - body - EN'
                          });
        $res = $ua->post($site . "/admin/article/add",
                         { 'image' => undef,
                           'category' => $cat_id,
                           'subcategory' => undef,
                           'tags' => undef,
                           'display_order' => 5,
                           'publish_date' => '12/05/2014',
                           'title_it' => 'Automatic test two - title - IT',
                           'text_it' => 'Automatic test two - body - IT',
                           'title_en' => 'Automatic test two - title - EN',
                           'text_en' => 'Automatic test two - body - EN'
                          });
        $res = $ua->post($site . "/admin/article/add",
                         { 'image' => undef,
                           'category' => $cat_id,
                           'subcategory' => undef,
                           'tags' => undef,
                           'display_order' => 20,
                           'publish_date' => '12/01/2014',
                           'title_it' => 'Automatic test three - title - IT',
                           'text_it' => 'Automatic test three - body - IT',
                           'title_en' => 'Automatic test three - title - EN',
                           'text_en' => 'Automatic test three - body - EN'
                          });
        my $articles = Strehler::Element::Article->get_list({ext => 1, language => 'it'});
        my $test_slug;
        foreach my $a (@{$articles->{'to_view'}})
        {
            if($a->{'title'} eq 'Automatic test one - title - IT')
            {
                $test_slug = $a->{'slug'};
            }
            $ua->get($site . "/admin/article/turnon/" . $a->{'id'});
        }

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
        
        $res = $ua->get($site . "/it/get-last-by-order/prova");        
        is($res->content, 'Automatic test three - title - IT', "Get Last By Orded - IT");
        $res = $ua->get($site . "/it/get-first-by-order/prova");        
        is($res->content, 'Automatic test two - title - IT', "Get First By Orded - IT");
        $res = $ua->get($site . "/en/get-first-by-order/prova");        
        is($res->content, 'Automatic test two - title - EN', "Get First By Orded - EN");
        $res = $ua->get($site . "/en/get-first-by-date/prova");        
        is($res->content, 'Automatic test three - title - EN', "Get First By Date - EN");
        $res = $ua->get($site . "/it/get-last-by-date/prova");        
        is($res->content, 'Automatic test two - title - IT', "Get Last By Date - IT");
        $res = $ua->get($site . "/it/slug/$test_slug");        
        is($res->content, 'Automatic test one - title - IT', "Get by Slug - IT");
    },
    server => sub {
        use Dancer2;
        my $port = shift;
        Dancer2->runner->server->port($port);
        start;
    },
);

done_testing;
