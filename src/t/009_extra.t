use strict;
use warnings;

use Test::More;
use Test::TCP;
use LWP::UserAgent;
use FindBin;
use Data::Dumper;

$ENV{DANCER_CONFDIR} = 't/testapp';
require t::testapp::lib::Site;
require t::testapp::lib::Site::Dummy;

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

        #Dummy add is blocked when no category is in the system [Dummy is a categorized entity
        $res = $ua->get($site . "/admin/dummy/add");
        like($res->content, qr/No category in the system/, "Dummy (categorized entity) add blocked because no category");

        #Puppet add is not blocked when no category is in the system [Dummy is a categorized entity
        $res = $ua->get($site . "/admin/puppet/add");
        like($res->content, qr/Submit/, "Puppet (not categorized entity) add allowed also with no category");

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

        ok(Site::Dummy->slugged(), "[configuration] Dummy has slug");

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
        is($dummy_object->get_attr('slug'), $dummy_id . '-a-dumb-text', "Slug correctly created");
        
        #CALL BY SLUG
        $res = $ua->get($site . "/dummyslug/".$dummy_object->get_attr('slug'));        
        is($res->content, $dummy_id, "Get by Slug on dummy");
        
        #DELETE
        $ua->default_header('X-Requested-With' => undef);
        $res = $ua->post($site . "/admin/dummy/delete/$dummy_id");
        $dummy_object = Site::Dummy->new($dummy_id);
        ok(! $dummy_object->exists(), "Dummy object correctly deleted");

    },
    server => sub {
        use Dancer2;
        my $port = shift;
        Site->runner->{'port'} = $port;
        start;
    },
);

done_testing;
