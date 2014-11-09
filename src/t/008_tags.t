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

        #Dummy category created for test purpose
        $res = $ua->post($site . "/admin/category/add",
                         { 'category' => 'prova-configured',
                           'parent' => '',
                           'tags-all' => 'tag1,tag2,tag3',
                           'default-all' => 'tag2',
                           'tags-article' => '',
                           'default-article' => '',
                           'tags-image' => '',
                           'default-image' => '' });
        $res = $ua->post($site . "/admin/category/add",
                         { 'category' => 'prova-open',
                           'parent' => '',
                         });
                   
        my $cat_conf = Strehler::Meta::Category->new({ category => 'prova-configured' });
        my $cat_open = Strehler::Meta::Category->new({ category => 'prova-open' });

        my $tags_configured_string = '<label>Tags</label>.*' .
                                    '<input type="checkbox" name="configured-tag" value="tag1" checked><span>tag1</span>.*' .
                                    '<input type="checkbox" name="configured-tag" value="tag2" ><span>tag2</span>.*' .
                                    '<input type="checkbox" name="configured-tag" value="tag3" ><span>tag3</span>.*';
        my $tags_configured_string_default = '<label>Tags</label>.*' .
                                    '<input type="checkbox" name="configured-tag" value="tag1" ><span>tag1</span>.*' .
                                    '<input type="checkbox" name="configured-tag" value="tag2" checked><span>tag2</span>.*' .
                                    '<input type="checkbox" name="configured-tag" value="tag3" ><span>tag3</span>.*';

        my $tags_open_string = '<label for="tags">Tags</label>.*' .
                                    '<input type="text" name="tags" value="foo".*';
        my $tags_open_string_default = '<label for="tags">Tags</label>.*' .
                                    '<input type="text" name="tags" value="">.*';
        #ARTICLE - CONFIGURED - ADD
        $res = $ua->post($site . "/admin/article/add",
                         { 'image' => undef,
                           'category' => $cat_conf->get_attr('id'),
                           'subcategory' => undef,
                           'tags' => 'tag1',
                           'display_order' => 14,
                           'publish_date' => '12/03/2014',
                           'title_it' => 'Article with configured tags',
                           'text_it' => 'Body - it',
                           'title_en' => 'Article with configured tags',
                           'text_en' => 'Body - en'
                          });
        my $articles = Strehler::Element::Article->get_list();
        my $article_configured = $articles->{'to_view'}->[0];
        my $article_configured_id = $article_configured->{'id'};
        my $article_configured_object = Strehler::Element::Article->new($article_configured_id);
        is($article_configured_object->get_tags(), 'tag1', "Article - Configured Tags - Tags correctly saved");

        #ARTICLE - OPEN - ADD
        $res = $ua->post($site . "/admin/article/add",
                         { 'image' => undef,
                           'category' => $cat_open->get_attr('id'),
                           'subcategory' => undef,
                           'tags' => 'foo',
                           'display_order' => 14,
                           'publish_date' => '12/03/2014',
                           'title_it' => 'Article with open tags',
                           'text_it' => 'Body - IT',
                           'title_en' => 'Article with open tags',
                           'text_en' => 'Body - EN'
                          });
        $articles = Strehler::Element::Article->get_list();
        my $article_open = $articles->{'to_view'}->[0];
        my $article_open_id = $article_open->{'id'};
        my $article_open_object = Strehler::Element::Article->new($article_open_id);
        is($article_open_object->get_tags(), 'foo', "Article - Open Tags - Tags correctly saved");
        
        $ua->default_header('X-Requested-With' => "XMLHttpRequest");

        #ARTICLE - CONFIGURED - EDIT (AJAX CALL TEST)
        $ua->default_header('X-Requested-With' => "XMLHttpRequest");
        $res = $ua->get($site . "/admin/article/tagform/$article_configured_id");
        my $response_content = $res->content;
        $response_content =~ s/\n//g;
        like($response_content, qr/$tags_configured_string/, "Article - Configured Tags - Correct AJAX response on edit");

        #ARTICLE - OPEN - EDIT (AJAX CALL TEST)
        $res = $ua->get($site . "/admin/article/tagform/$article_open_id");
        $response_content = $res->content;
        $response_content =~ s/\n//g;
        like($response_content, qr/$tags_open_string/, "Article - Open Tags - Correct AJAX response on edit");

        $ua->default_header('X-Requested-With' => undef);

        #IMAGE - CONFIGURED - ADD
        $res = $ua->post($site . "/admin/image/add",
                         'Content_Type' => 'form-data',
                         'Content' =>  [
                            'category' => $cat_conf->get_attr('id'),
                            'subcategory' => undef,
                            'tags' => 'tag1',
                            'title_it' => 'Image - Configured tags',
                            'description_it' => 'Body - IT',
                            'title_en' => 'Image - Configured tags',
                            'description_en' => 'Body - EN',
			                'photo' => ['t/res/strehler.jpg', 'strehler.jpg', 'Content-Type' => 'image/jpg']
                            ]
                          );
        
        my $images = Strehler::Element::Image->get_list();
        my $image_configured = $images->{'to_view'}->[0];
        my $image_configured_id = $image_configured->{'id'};
        my $image_configured_object = Strehler::Element::Image->new($image_configured_id);
        is($image_configured_object->get_tags(), 'tag1', "Image - Configured Tags - Tags correctly saved");

        #IMAGE - OPEN - ADD
        $res = $ua->post($site . "/admin/image/add",
                         'Content_Type' => 'form-data',
                         'Content' =>  [
                            'category' => $cat_open->get_attr('id'),
                            'subcategory' => undef,
                            'tags' => 'foo',
                            'title_it' => 'Image - Open tags',
                            'description_it' => 'Body - IT',
                            'title_en' => 'Image - Open tags',
                            'description_en' => 'Body - EN',
			                'photo' => ['t/res/strehler.jpg', 'strehler.jpg', 'Content-Type' => 'image/jpg']
                            ]
                          );
        
        $images = Strehler::Element::Image->get_list();
        my $image_open = $images->{'to_view'}->[0];
        my $image_open_id = $image_open->{'id'};
        my $image_open_object = Strehler::Element::Image->new($image_open_id);
        is($image_open_object->get_tags(), 'foo', "Image - Open Tags - Tags correctly saved");

        $ua->default_header('X-Requested-With' => "XMLHttpRequest");

        #IMAGE - CONFIGURED - EDIT (AJAX CALL TEST)
        $ua->default_header('X-Requested-With' => "XMLHttpRequest");
        $res = $ua->get($site . "/admin/image/tagform/$image_configured_id");
        $response_content = $res->content;
        $response_content =~ s/\n//g;
        like($response_content, qr/$tags_configured_string/, "Image - Configured Tags - Correct AJAX response on edit");

        #IMAGE - OPEN - EDIT (AJAX CALL TEST)
        $res = $ua->get($site . "/admin/image/tagform/$image_open_id");
        $response_content = $res->content;
        $response_content =~ s/\n//g;
        like($response_content, qr/$tags_open_string/, "Image - Open Tags - Correct AJAX response on edit");

       
        unlink 't/testapp/public/upload/strehler.jpg';

        #DUMMY - CONFIGURED - ADD
        $res = $ua->post($site . "/admin/dummy/add",
                         {
                           'category' => $cat_conf->get_attr('id'),
                           'subcategory' => undef,
                           'tags' => 'tag1',
                           'text' => 'dummy configured tags'
                          });
        my $dummies = Site::Dummy->get_list();
        my $dummy_configured = $dummies->{'to_view'}->[0];
        my $dummy_configured_id = $dummy_configured->{'id'};
        my $dummy_configured_object = Site::Dummy->new($article_configured_id);
        is($article_configured_object->get_tags(), 'tag1', "Dummy - Configured Tags - Tags correctly saved");

        #DUMMY - OPEN - ADD
        $res = $ua->post($site . "/admin/dummy/add",
                         { 
                           'category' => $cat_open->get_attr('id'),
                           'subcategory' => undef,
                           'tags' => 'foo',
                           'text' => 'dummy open tags'
                          });
        $dummies = Site::Dummy->get_list();
        my $dummy_open = $dummies->{'to_view'}->[0];
        my $dummy_open_id = $dummy_open->{'id'};
        my $dummy_open_object = Site::Dummy->new($dummy_open_id);
        is($dummy_open_object->get_tags(), 'foo', "Dummy - Open Tags - Tags correctly saved");
        
        $ua->default_header('X-Requested-With' => "XMLHttpRequest");

        #DUMMY - CONFIGURED - EDIT (AJAX CALL TEST)
        $ua->default_header('X-Requested-With' => "XMLHttpRequest");
        $res = $ua->get($site . "/admin/dummy/tagform/$dummy_configured_id");
        $response_content = $res->content;
        $response_content =~ s/\n//g;
        like($response_content, qr/$tags_configured_string/, "Dummy - Configured Tags - Correct AJAX response on edit");

        #DUMMY - OPEN - EDIT (AJAX CALL TEST)
        $res = $ua->get($site . "/admin/dummy/tagform/$dummy_open_id");
        $response_content = $res->content;
        $response_content =~ s/\n//g;
        like($response_content, qr/$tags_open_string/, "Dummy - Open Tags - Correct AJAX response on edit");

         #ARTICLE - OPEN - FRESH BOX SELECTING CATEGORY
        $res = $ua->get($site . "/admin/category/tagform/article/".$cat_open->get_attr('id'));
        $response_content = $res->content;
        $response_content =~ s/\n//g;
        like($response_content, qr/$tags_open_string_default/, "Article - Open Tags - Box generated on category select OK");

        #ARTICLE - CONFIGURED - FRESH BOX SELECTING CATEGORY
        $res = $ua->get($site . "/admin/category/tagform/article/".$cat_conf->get_attr('id'));
        $response_content = $res->content;
        $response_content =~ s/\n//g;
        like($response_content, qr/$tags_configured_string_default/, "Article - Configured Tags - Box generated on category select OK");

        #IMAGE - OPEN - FRESH BOX SELECTING CATEGORY
        $res = $ua->get($site . "/admin/category/tagform/image/".$cat_open->get_attr('id'));
        $response_content = $res->content;
        $response_content =~ s/\n//g;
        like($response_content, qr/$tags_open_string_default/, "Image - Open Tags - Box generated on category select OK");

        #IMAGE - CONFIGURED - FRESH BOX SELECTING CATEGORY
        $res = $ua->get($site . "/admin/category/tagform/image/".$cat_conf->get_attr('id'));
        $response_content = $res->content;
        $response_content =~ s/\n//g;
        like($response_content, qr/$tags_configured_string_default/, "Image - Configured Tags - Box generated on category select OK");

        #DUMMY - OPEN - FRESH BOX SELECTING CATEGORY
        $res = $ua->get($site . "/admin/category/tagform/dummy/".$cat_open->get_attr('id'));
        $response_content = $res->content;
        $response_content =~ s/\n//g;
        like($response_content, qr/$tags_open_string_default/, "Dummy - Open Tags - Box generated on category select OK");

        #DUMMY - CONFIGURED - FRESH BOX SELECTING CATEGORY
        $res = $ua->get($site . "/admin/category/tagform/dummy/".$cat_conf->get_attr('id'));
        $response_content = $res->content;
        $response_content =~ s/\n//g;
        like($response_content, qr/$tags_configured_string_default/, "Dummy - Configured Tags - Box generated on category select OK");

    },
    server => sub {
        use Dancer2;
        my $port = shift;
        Dancer2->runner->{'port'} = $port;
        start;
    },
);

done_testing;
