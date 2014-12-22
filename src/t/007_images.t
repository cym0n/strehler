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
    
    my $r = $cb->(GET '/admin/image/add');
    like($r->content, qr/No category in the system/, "Image add blocked because no category");

    ok(! Strehler::Element::Image->slugged(), "[configuration] Image hasn't slug");

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

    #LIST
    $r = $cb->(GET '/admin/image/list');
    is($r->code, 200, "Images page correctly accessed");
    $r = $cb->(GET '/admin/image/list?order-by=descriptions.title&order=asc');
    is($r->code, 200, "Images page correctly accessed (ordering parameters added)");
    #ADD        
    $r = $cb->(POST "/admin/image/add",
                    'Content_Type' => 'form-data',
                    'Content' =>  [
                            'category' => $cat_id,
                            'subcategory' => undef,
                            'tags' => 'tag1',
                            'title_it' => 'Automatic test - title - IT',
                            'description_it' => 'Automatic test - body - IT',
                            'title_en' => 'Automatic test - title - EN',
                            'description_en' => 'Automatic test - body - EN',
			                'photo' => ['t/res/strehler.jpg', 'strehler.jpg', 'Content-Type' => 'image/jpg']
                            ]
                 );
    my $images = Strehler::Element::Image->get_list();
    my $image = $images->{'to_view'}->[0];
    my $image_id = $image->{'id'};
    my $image_object = Strehler::Element::Image->new($image_id);
    ok($image_object->exists(), "Image correctly inserted");

    #AJAX CALL FOR ARTICLE EDIT
    my $req = HTTP::Request->new(GET => $site . "/admin/image/src/$image_id");
    $req->header('X-Requested-With' => 'XMLHttpRequest');
    $r = $cb->($req); 
    is($r->content, '/upload/strehler.jpg', "Ajax call for image source works");

    ok(-e "t/testapp/public/upload/strehler.jpg", "Image resource in place");

    #DELETE
    $r = $cb->(POST "/admin/image/delete/$image_id");
    $image_object = Strehler::Element::Article->new($image_id);
    ok(! $image_object->exists(), "Image correctly deleted");

    unlink 't/testapp/public/upload/strehler.jpg';
};
done_testing();
