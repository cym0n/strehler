use strict;
use warnings;

use Test::More;
use Test::TCP;
use LWP::UserAgent;
use FindBin;

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
        
        #LIST
        $res = $ua->get($site . "/admin/category/list");
        is($res->code, 200, "Category page correctly accessed");

        #ADD        
        $res = $ua->get($site . "/admin/category/add");
        my $entity_string = '<div class="alert alert-info">.*All.*</div>';
        like($res->content, qr/$entity_string/s, "All present in category add page for tags");
        foreach my $t ('article', 'image', 'dummy', 'foo')
        {
            my $entity_string = '<div class="alert alert-info">.*Per ' . $t . '.*</div>';
            like($res->content, qr/$entity_string/s, "$t present in category add page for tags");
        }
        $entity_string = '<div class="alert alert-info">.*Per puppet.*</div>';
        unlike($res->content, qr/$entity_string/s, "Puppet not present in category add page for tags");

        $res = $ua->post($site . "/admin/category/add",
                         { 'category' => 'prova',
                           'parent' => '',
                           'tags-all' => 'tag1,tag2,tag3',
                           'default-all' => 'tag2',
                           'tags-article' => '',
                           'default-article' => '',
                           'tags-image' => '',
                           'default-image' => '' });
        is($res->code, 200, "New category successfully posted");
        my $cat = Strehler::Meta::Category->new({ category => 'prova' });
        my $cat_id = $cat->get_attr('id');
        ok($cat->exists(), "Category inserted");

        $res = $ua->post($site . "/admin/category/add",
                         { 'category' => 'prova2',
                           'parent' => '',
                           'tags-all' => '',
                           'default-all' => '',
                           'tags-article' => 'tagart1,tagart2,tagart3',
                           'default-article' => '',
                           'tags-image' => '',
                           'default-image' => '' });
        my $cat2 = Strehler::Meta::Category->new({ category => 'prova2' });
        my $cat2_id = $cat2->get_attr('id');

        #SELECT
        my $select_string = '<option value="' . $cat->get_attr('id') . '">prova</option>';
        $ua->default_header('X-Requested-With' => "XMLHttpRequest");
        $res = $ua->get($site . "/admin/category/select");
        like($res->content, qr/$select_string/, "Categories select combo correctly generated");

        #DELETE
        $ua->default_header('X-Requested-With' => undef);
        $res = $ua->post($site . "/admin/category/delete/$cat_id");
        is($res->code, 200, "Category deletion answers OK");
        my $cat_again = Strehler::Meta::Category->new({ category => 'prova' });
        ok(! $cat_again->exists(), "Category deleted");

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
