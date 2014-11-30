use strict;
use warnings;

use Test::More;
use Test::TCP;
use LWP::UserAgent;
use FindBin;
use Dancer2::Serializer::JSON;
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
                           'publish_date' => '13/11/2009',
                           'title_it' => 'Automatic test 2 - title - IT',
                           'text_it' => 'Automatic test 2 - body - IT',
                           'title_en' => 'Automatic test 2 - title - EN',
                           'text_en' => 'Automatic test 2 - body - EN'
                          });
        $res = $ua->post($site . "/admin/article/add",
                         { 'image' => undef,
                           'category' => $ancestor_cat_id,
                           'subcategory' => $child_cat_id,
                           'tags' => '',
                           'display_order' => 3,
                           'publish_date' => '',
                           'title_it' => 'Automatic test 3 - title - IT',
                           'text_it' => 'Automatic test 3 - body - IT',
                           'title_en' => 'Automatic test 3 - title - EN',
                           'text_en' => 'Automatic test 3 - body - EN'
                          });              
        $res = $ua->post($site . "/admin/dummy/add",
                         { 'category' => $ancestor_cat_id,
                           'subcategory' => undef,
                           'tags' => 'tag1',
                           'text' => 'A dumb text',
                         });

        #Dummy articles published
        my $not_published_id = undef;
        my $bad_id = 0;
        
        my $all_created = Strehler::Element::Article->get_list();
        for(@{$all_created->{to_view}})
        {
            my $el = $_;
            $bad_id += $el->{'id'};
            if($el->{'title'} ne 'Automatic test 3 - title - IT')
            {
                $ua->get($site . "/admin/article/turnon/" . $el->{'id'});
            }
            else
            {
                $not_published_id = $el->{'id'};
            }
        }
        
        #TEST 
        my $serializer = Dancer2::Serializer::JSON->new();        
        my $content;        
        my @elements;

        $res = $ua->get($site . "/api/v1/articles/");
        is($res->code, 200, "Articles api correctly called");
        $content = $serializer->deserialize($res->content);
        @elements = @{$content->{to_view}};
        is(@elements, 2, "Elements retrived: 2");
        is($elements[0]->{'title'}, 'Automatic test 2 - title - IT', "Ordered by ID, desc");

        $res = $ua->get($site . "/api/v1/articles/?order_by=display_order&order=asc");
        $content = $serializer->deserialize($res->content);
        @elements = @{$content->{to_view}};
        is($elements[0]->{'title'}, 'Automatic test 1 - title - IT', "Ordered by display order, asc");

        $res = $ua->get($site . "/api/v1/articles/?entries_per_page=1");
        $content = $serializer->deserialize($res->content);
        @elements = @{$content->{to_view}};
        is($#elements, 0, "Entries for page configured to 1");

        $res = $ua->get($site . "/api/v1/articles/?lang=en");
        $content = $serializer->deserialize($res->content);
        @elements = @{$content->{to_view}};
        is($elements[0]->{'title'}, 'Automatic test 2 - title - EN', "Different language");

        $res = $ua->get($site . "/api/v1/articles/prova/foo/");
        is($res->code, 200, "Articles api correctly called on category");
        $content = $serializer->deserialize($res->content);
        @elements = @{$content->{to_view}};
        is(@elements, 1, "Elements retrived: 1");
        is($elements[0]->{'title'}, 'Automatic test 2 - title - IT', "Correct element retrieved");

        my $element_id = $elements[0]->{'id'};
        $res = $ua->get($site . "/api/v1/article/" . $element_id);
        is($res->code, 200, "Single article API correctly called");
        $content = $serializer->deserialize($res->content);
        is($content->{'title'}, 'Automatic test 2 - title - IT', "Correct element retrieved");            

        my $element_slug = $elements[0]->{'slug'};
        $res = $ua->get($site . "/api/v1/article/slug/" . $element_slug);
        is($res->code, 200, "Single article API by slug correctly called");
        $content = $serializer->deserialize($res->content);
        is($content->{'title'}, 'Automatic test 2 - title - IT', "Correct element retrieved using slug");            

        $res = $ua->get($site . "/api/v1/article/" . $element_id . '?callback=foo');
        is($res->code, 200, "Single article API correctly called as JSONP");
        like($res->content, qr/^foo\(.*?\)/, "JSONP padding present");

        $res = $ua->get($site . "/api/v1/article/" . $bad_id);
        is($res->code, 404, "Element not found");
        
        $res = $ua->get($site . "/api/v1/article/" . $not_published_id);
        is($res->code, 404, "Element not found");

        $res = $ua->get($site . "/api/v1/dummies/");
        is($res->code, 200, "Dummies api correctly called");
        $content = $serializer->deserialize($res->content);
        @elements = @{$content->{to_view}};
        is(@elements, 1, "Dummy elements retrived: 1");
        is($elements[0]->{'text'}, 'A dumb text', "Dummy - Ordered by ID, desc");

        my $dummy_id = $elements[0]->{'id'};
        $res = $ua->get($site . "/api/v1/dummy/" . $dummy_id);
        is($res->code, 200, "Single dummy API correctly called");
        $content = $serializer->deserialize($res->content);
        is($content->{'text'}, 'A dumb text', "Dummy - Correct element retrieved");            

        my $dummy_slug = $elements[0]->{'slug'};
        $res = $ua->get($site . "/api/v1/dummy/slug/" . $dummy_slug);
        is($res->code, 200, "Single dummy API by slug correctly called");
        $content = $serializer->deserialize($res->content);
        is($content->{'text'}, 'A dumb text', "Dummy - Correct element retrieved using slug");            



    },
    server => sub {
        use Dancer2;
        my $port = shift;
        Dancer2->runner->{'port'} = $port;
        start;
    },
);

done_testing;
