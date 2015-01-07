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
$ENV{DANCER_ENVIRONMENT} = 'dashboard';
require t::testapp::lib::TestSupport;
require Strehler::Admin;


TestSupport::reset_database();

my $app = Strehler::Admin->to_app;

test_psgi $app, sub {
    my $cb = shift;
    my $site = "http://localhost";

    #Dummy categories created for test purpose
    my $listed_cat_id = TestSupport::create_category($cb, 'listed');
    my $upper_cat_id = TestSupport::create_category($cb, 'upper');
    my $lower_cat_id = TestSupport::create_category($cb, 'lower');

    #Listed page: three contents, two online, just one english (not online)

    TestSupport::create_article($cb, 'listed1', $listed_cat_id, undef, { title_en => undef, text_en => undef });
    TestSupport::create_article($cb, 'listed2', $listed_cat_id, undef, { title_en => undef, text_en => undef });
    TestSupport::create_article($cb, 'listed3', $listed_cat_id);

    #Custom page: two contents online for italian, just one online for english
    # upper IT: pub & unpub [page1 & page2]
    # lower IT: pub [page3, page4 is older than online]
    # upper EN: unpub [page2]
    # lower EN: nothing
    
    TestSupport::create_article($cb, 'page1', $upper_cat_id, undef, { publish_date => '10/10/2014', title_en => undef, text_en => undef });
    TestSupport::create_article($cb, 'page2', $upper_cat_id, undef, { publish_date => '12/11/2015' });
    TestSupport::create_article($cb, 'page3', $lower_cat_id, undef, { display_order => 100, title_en => undef, text_en => undef });
    TestSupport::create_article($cb, 'page4', $lower_cat_id, undef, { display_order => 1 , title_en => undef, text_en => undef });

    #Online: listed1, listed2, page1, page3

    my $contents = Strehler::Element::Article->get_list();
    foreach my $c (@{$contents->{to_view}})
    {
        if($c->{'title'} eq 'Automatic test listed1 - title - IT' ||
           $c->{'title'} eq 'Automatic test listed2 - title - IT' ||
           $c->{'title'} eq 'Automatic test page1 - title - IT' ||
           $c->{'title'} eq 'Automatic test page3 - title - IT' )
        {
            my $r = $cb->(GET "/admin/article/turnon/" . $c->{'id'});
        }
    }
    my $r = $cb->(GET "/admin/dashboard/it");
    is($r->code, 200, "Italian dashboard successfully called");
    my $content = $r->decoded_content;
    like($content, list_box('2/3'), "List box correctly displayed - IT");
    like($content, page_box('2/2', 'OK'), "Page box correctly displayed - IT");
    like($content, page_section_box('it', 'lower', 1, 0, 'order'), "Section for lower category matched - IT");
    like($content, page_section_box('it', 'upper', 1, 1, 'date'), "Section for upper category matched - IT");

    $r = $cb->(GET "/admin/dashboard/en");
    is($r->code, 200, "English dashboard successfully called");
    $content = $r->decoded_content;
    like($content, list_box('0/1'), "List box correctly displayed - EN");
    like($content, page_box('0/2', 'KO'), "Page box correctly displayed - EN");
    like($content, page_section_box('en', 'lower', 0, 0, 'order'), "Section for lower category matched - EN");
    like($content, page_section_box('en', 'upper', 0, 1, 'date'), "Section for upper category matched - EN");
};

done_testing;

sub list_box
{
    my $counter = shift;
    my $match =  '<div class="well span5">.*' .
                 '<h4 class="dashboard-title">listed contents<\/h4>.*' .
                 '<h5 class="dashboard-subtitle">List content</h5>.*' .
                 '<p class="dashboard-box-p">.*' .
                 'Category: listed<br />.*' .
                 'Elements: ' . $counter . '.*' .
                 '</p>';
    return qr/$match/s;
}
sub page_box
{
    my $counter = shift;
    my $status = shift;
    my $match = '<div class="well span5">.*' .
                '<h4 class="dashboard-title">a page</h4>.*' .
                '<h5 class="dashboard-subtitle">Custom page</h5>.*' .
                '<p class="dashboard-box-p">.*' .
                'Elements: ' . $counter . '<br />.*';
    if($status eq 'OK')
    {
        $match .= '<span class="text-success">Status: <strong>OK</strong></span>';
    }
    elsif($status eq 'KO')
    {
        $match .= '<span class="text-error">Status: <strong>KO</strong></span>';
    }
    return qr/$match/s;
}

sub page_section_box
{
    my $language = shift;
    my $category = shift;
    my $pub = shift;
    my $unpub = shift;
    my $by = shift || 'date';
    my $form_param;
    my $order_by_param;
    if($by eq 'date')
    {
        $form_param = '&strehl-today=1';
        $order_by_param = '&order-by=publish_date';
    }
    elsif($by eq 'order')
    {
        $form_param = '&strehl-max-order=1';
        $order_by_param = '&order-by=display_order';
    }
    my $match =  '<div>.*?' .
                 '<p>.*?' .
                 '<strong>.*?</strong><br />.*?' .
                 'Category: ' . $category . '<br />.*?';
                 if($pub)
                 {
                    $match .= '<span class="text-success">Content online</span>.*?';
                 }
                 else
                 {
                    $match .= '<span class="text-error">No content published!</span>.*?';
                 }
                 $match .= '</p>.*?' .
                 '</div>.*?' .
                 '<div class="btn-group dashboard-section-buttons">.*?';
                 if($pub)
                 {
                    $match .= '<a class="btn" href="/admin/article/edit/[0-9]+\?strehl-from=/admin/dashboard/' . $language . '"><span class="icon-eye-open"></span> Edit online</a>.*?';
                 }
                 else
                 {
                 }
                 if($unpub)
                 {
                     $match .= '<a class="btn" href="/admin/article/edit/[0-9]+\?strehl-from=/admin/dashboard/' . $language . '"><span class="icon-edit"></span> Edit draft</a>.*?' .
                               '<a class="btn" href="/admin/article/turnon/[0-9]+\?strehl-from=/admin/dashboard/' . $language . '"><span class="icon-circle-arrow-right"></span> Publish draft</a>.*';
                 }
                 else
                 {
                    $match .= '<a class="btn" href="/admin/article/add\?strehl-catname=' . $category . $form_param . '&strehl-from=/admin/dashboard/' . $language . '"><span class="icon-plus"></span> New draft</a>.*?'; 
                 }
                 $match .= '<a class="btn" href="/admin/article/list\?strehl-catname=' . $category . '&strehl-from=/admin/dashboard/' . $language . $order_by_param . '&order=desc&language=' . $language . '"><span class="icon-list"></span> All contents in category</a>.*?' .
                 '</div>';
    return qr/$match/s;
}
