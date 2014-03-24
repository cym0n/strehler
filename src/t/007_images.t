use strict;
use warnings;

use Test::More;
use Test::TCP;
use LWP::UserAgent;
use FindBin;
use Data::Dumper;
use File::Slurp;

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
        $res = $ua->get($site . "/admin/image/list");
        is($res->code, 200, "Images page correctly accessed");

        #ADD        
        $res = $ua->post($site . "/admin/image/add",
                         'Content_Type' => 'form-data',
                         'Content' =>  [
                            'category' => $cat_id,
                            'subcategory' => undef,
                            'tags' => undef,
                            'title_it' => 'Automatic test - title - IT',
                            'description_it' => 'Automatic test - body - IT',
                            'title_en' => 'Automatic test - title - EN',
                            'description_en' => 'Automatic test - body - EN',
			                'photo' => ['t/res/strehler.jpg', 'strehler.jpg', 'Content-Type' => 'image/jpg']
                            ]
                          );
        is($res->code, 200, "New image successfully posted");

        my $images = Strehler::Element::Image->get_list();
        my $image = $images->{'to_view'}->[0];
        my $image_id = $image->{'id'};
        my $image_object = Strehler::Element::Image->new($image_id);
        ok($image_object->exists(), "Image correctly inserted");
        
        $res = $ua->get($site . "/upload/strehler.jpg");
        is($res->code, 200, "Image resource in place");

        #AJAX CALL FOR ARTICLE EDIT
        $ua->default_header('X-Requested-With' => "XMLHttpRequest");
        $res = $ua->get($site . "/admin/image/src/$image_id");
        is($res->content, '/upload/strehler.jpg', "Ajax call for image source works");
    
        #DELETE
        $ua->default_header('X-Requested-With' => undef);
        $res = $ua->post($site . "/admin/image/delete/$image_id");
        $image_object = Strehler::Element::Article->new($image_id);
        ok(! $image_object->exists(), "Image correctly deleted");

        unlink 't/testapp/public/upload/strehler.jpg';

    },
    server => sub {
        use Dancer2;
        my $port = shift;
        Dancer2->runner->server->port($port);
        start;
        chdir "t/testapp";
    },
);

done_testing;
