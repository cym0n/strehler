use strict;
use warnings;

use Test::More;
use Test::TCP;
use LWP::UserAgent;
use FindBin;
use Data::Dumper;

use t::testapp::lib::Site;
use t::testapp::lib::Site::Dummy;

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
        $res = $ua->get($site . "/admin/dummy/list");
        is($res->code, 200, "Dummy list page correctly accessed");

        #ADD        
        $res = $ua->post($site . "/admin/dummy/add",
                         { 'category' => $cat_id,
                           'subcategory' => undef,
                           'tags' => 'tag1',
                           'text' => 'A dumb text',
                          });
        is($res->code, 200, "New dummy object successfully posted");
        my $dummies = Site::Dummy->get_list();
        my $dummy = $dummies->{'to_view'}->[0];
        my $dummy_id = $dummy->{'id'};
        my $dummy_object = Site::Dummy->new($dummy_id);
        ok($dummy_object->exists(), "Dummy object correctly inserted");

        #DELETE
        $ua->default_header('X-Requested-With' => undef);
        $res = $ua->post($site . "/admin/dummy/delete/$dummy_id");
        $dummy_object = Site::Dummy->new($dummy_id);
        ok(! $dummy_object->exists(), "Dummy object correctly deleted");

    },
    server => sub {
        use Dancer2;
        my $port = shift;
        if($Dancer2::VERSION < 0.14)
        {
            Site->runner->server->port($port);
        }
        else
        {
            Site->runner->{'port'} = $port;
        }
        start;
    },
);

done_testing;
