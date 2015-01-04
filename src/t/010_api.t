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
require t::testapp::lib::TestSupport;
require Strehler::Admin;
require Strehler::API;

TestSupport::reset_database();

my $admin_app = Strehler::Admin->to_app;
my $site_app = Strehler::API->to_app;

my $bad_id;
my $not_published_id;

test_psgi $admin_app, sub {
    my $cb = shift;
    my $site = "http://localhost";

    #Dummy categories created for test purpose
    my $ancestor_cat_id = TestSupport::create_category($cb, 'prova');
    my $child_cat_id = TestSupport::create_category($cb, 'foo', $ancestor_cat_id);
    TestSupport::create_article($cb, '1', $ancestor_cat_id, undef, { 'display_order' => 1, 'publish_date' => '' });
    TestSupport::create_article($cb, '2', $ancestor_cat_id, $child_cat_id, { 'display_order' => 2, 'publish_date' => '13/11/2009' });
    TestSupport::create_article($cb, '3', $ancestor_cat_id, $child_cat_id, { 'display_order' => 3, 'publish_date' => '' });
    my $r = $cb->(POST $site . "/admin/dummy/add",
                         { 'category' => $ancestor_cat_id,
                           'subcategory' => undef,
                           'tags' => 'tag1',
                           'text' => 'A dumb text',
                         });

    #Dummy articles published
    $not_published_id = undef;
    $bad_id = 0;
        
    my $all_created = Strehler::Element::Article->get_list();
    for(@{$all_created->{to_view}})
    {
        my $el = $_;
        $bad_id += $el->{'id'};
        if($el->{'title'} ne 'Automatic test 3 - title - IT')
        {
            $cb->(GET "/admin/article/turnon/" . $el->{'id'});
        }
        else
        {
            $not_published_id = $el->{'id'};
        }
    }
};
test_psgi $site_app, sub {
    my $cb = shift;
    my $site = "http://localhost";

    my $serializer = Dancer2::Serializer::JSON->new();        
    my $content;        
    my @elements;

    my $r = $cb->(GET "/api/v1/articles/");
    is($r->code, 200, "Articles api correctly called");
    $content = $serializer->deserialize($r->content);
    @elements = @{$content->{to_view}};
    is(@elements, 2, "Elements retrived: 2");
    is($elements[0]->{'title'}, 'Automatic test 2 - title - IT', "Ordered by ID, desc");

    $r = $cb->(GET "/api/v1/articles/?order_by=display_order&order=asc");
    $content = $serializer->deserialize($r->content);
    @elements = @{$content->{to_view}};
    is($elements[0]->{'title'}, 'Automatic test 1 - title - IT', "Ordered by display order, asc");

    $r = $cb->(GET "/api/v1/articles/?entries_per_page=1");
    $content = $serializer->deserialize($r->content);
    @elements = @{$content->{to_view}};
    is($#elements, 0, "Entries for page configured to 1");

    $r = $cb->(GET "/api/v1/articles/?lang=en");
    $content = $serializer->deserialize($r->content);
    @elements = @{$content->{to_view}};
    is($elements[0]->{'title'}, 'Automatic test 2 - title - EN', "Different language");

    $r = $cb->(GET "/api/v1/articles/prova/foo/");
    is($r->code, 200, "Articles api correctly called on category");
    $content = $serializer->deserialize($r->content);
    @elements = @{$content->{to_view}};
    is(@elements, 1, "Elements retrived: 1");
    is($elements[0]->{'title'}, 'Automatic test 2 - title - IT', "Correct element retrieved");

    my $element_id = $elements[0]->{'id'};
    $r = $cb->(GET "/api/v1/article/" . $element_id);
    is($r->code, 200, "Single article API correctly called");
    $content = $serializer->deserialize($r->content);
    is($content->{'title'}, 'Automatic test 2 - title - IT', "Correct element retrieved");            

    my $element_slug = $elements[0]->{'slug'};
    $r = $cb->(GET "/api/v1/article/slug/" . $element_slug);
    is($r->code, 200, "Single article API by slug correctly called");
    $content = $serializer->deserialize($r->content);
    is($content->{'title'}, 'Automatic test 2 - title - IT', "Correct element retrieved using slug");            

    $r = $cb->(GET "/api/v1/article/" . $element_id . '?callback=foo');
    is($r->code, 200, "Single article API correctly called as JSONP");
    like($r->content, qr/^foo\(.*?\)/, "JSONP padding present");

    $r = $cb->(GET "/api/v1/article/" . $bad_id);
    is($r->code, 404, "Element not found");
        
    $r = $cb->(GET "/api/v1/article/" . $not_published_id);
    is($r->code, 404, "Element not found");

    $r = $cb->(GET "/api/v1/dummies/");
    is($r->code, 200, "Dummies api correctly called");
    $content = $serializer->deserialize($r->content);
    @elements = @{$content->{to_view}};
    is(@elements, 1, "Dummy elements retrived: 1");
    is($elements[0]->{'text'}, 'A dumb text', "Dummy - Ordered by ID, desc");

    my $dummy_id = $elements[0]->{'id'};
    $r = $cb->(GET "/api/v1/dummy/" . $dummy_id);
    is($r->code, 200, "Single dummy API correctly called");
    $content = $serializer->deserialize($r->content);
    is($content->{'text'}, 'A dumb text', "Dummy - Correct element retrieved");            

    my $dummy_slug = $elements[0]->{'slug'};
    $r = $cb->(GET "/api/v1/dummy/slug/" . $dummy_slug);
    is($r->code, 200, "Single dummy API by slug correctly called");
    $content = $serializer->deserialize($r->content);
    is($content->{'text'}, 'A dumb text', "Dummy - Correct element retrieved using slug");            
};
done_testing;
