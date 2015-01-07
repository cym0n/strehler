package TestSupport;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/testapp/lib";
use JSON;
use Dancer2;
use Dancer2::Plugin::DBIC;
use HTTP::Request;
use HTTP::Request::Common;
use Strehler::Meta::Category;

sub reset_database
{
    my $schema = config->{'Strehler'}->{'schema'} ? schema config->{'Strehler'}->{'schema'} : schema;
    $schema->resultset('ActivityLog')->delete_all();
    $schema->resultset('Article')->delete_all();
    $schema->resultset('Category')->delete_all();
    $schema->resultset('ConfiguredTag')->delete_all();
    $schema->resultset('Content')->delete_all();
    $schema->resultset('Description')->delete_all();
    $schema->resultset('Image')->delete_all();
    $schema->resultset('Tag')->delete_all();
    $schema->resultset('Dummy')->delete_all();
    $schema->resultset('User')->search({ user => { 'not in' => ['admin', 'editor']}})->delete_all();
}

sub keep_logged
{
    my $cb = shift;
    my $jar = shift;
    my $req = shift;
    $jar->add_cookie_header($req);
    my $r = $cb->($req); 
    $jar->extract_cookies($r);
    return ($r, $jar);
}

sub create_category
{
    my $cb = shift;
    my $name = shift;
    my $parent = shift || '';
    my $r = $cb->( POST '/admin/category/add', 
                    [ 'category' => $name,
                      'parent' => $parent,
                      'tags-all' => 'tag1,tag2,tag3',
                      'default-all' => 'tag2',
                      'tags-article' => '',
                      'default-article' => '',
                      'tags-image' => '',
                      'default-image' => '' ] );
    if($parent)
    {
        my $ancestor = Strehler::Meta::Category->new($parent);
        $name = $ancestor->get_attr('category') . '/' . $name;
    }
    my $cat = Strehler::Meta::Category->explode_name($name);
    return $cat->get_attr('id');
}
sub create_article
{
    my $cb = shift;
    my $counter = shift || '';
    my $category = shift || '';
    my $subcategory = shift || '';
    my $custom_params = shift || {};
    my $r = $cb->( POST '/admin/article/add', 
                    [ 'image' => undef,
                      'category' => $category,
                      'subcategory' => $subcategory,
                      'tags' => exists $custom_params->{'tags'} ? $custom_params->{'tags'} : 'tag1',
                      'display_order' => exists $custom_params->{'display_order'} ? $custom_params->{'display_order'} : 14,
                      'publish_date' => exists $custom_params->{'publish_date'} ? $custom_params->{'publish_date'} : '12/03/2014',
                      'title_it' => exists $custom_params->{'title_it'} ? $custom_params->{'title_it'} : 'Automatic test ' . $counter . ' - title - IT',
                      'text_it' => exists $custom_params->{'text_it'} ? $custom_params->{'text_it'} : 'Automatic test ' . $counter . ' - body - IT',
                      'title_en' => exists $custom_params->{'title_en'} ? $custom_params->{'title_en'} : 'Automatic test ' . $counter . ' - title - EN',
                      'text_en' => exists $custom_params->{'text_en'} ? $custom_params->{'text_en'} : 'Automatic test ' . $counter . ' - body - EN' 
                     ]);
}
sub list_reader
{
    my $content = shift;
    my @ids;
    my $table_line_flag = 0;
    for (split /^/, $content) 
    {
        my $line = $_;
        if($line =~ /<tr>/)
        {
            $table_line_flag = 1;
        }
        else
        {
            if($table_line_flag == 1)
            {
                if($line =~ /<td>([0-9]+)<\/td>/)
                {
                    push @ids, $1;
                }
            }
            $table_line_flag = 0;
        }
    }
    return @ids; 
}

1;

