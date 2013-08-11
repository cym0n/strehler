package Strehler::Element::Article;

use Moo;
use Dancer2 ":syntax";
use Dancer2::Plugin::DBIC;
use Data::Dumper;

has row => (
    is => 'ro',
);

sub BUILDARGS {
   my ( $class, @args ) = @_;
   my $id = shift @args; 
   my $img_row = schema->resultset('Article')->find($id);
   return { row => $img_row };
};

sub get_form_data
{
    my $self = shift;
    my $article_row = $self->row;
    my @contents = $article_row->contents;
    my $data;
    $data->{'category'} = $article_row->category->id;
    $data->{'image'} = $article_row->image;
    $data->{'order'} = $article_row->display_order;
    $data->{'publish_date'} = $article_row->publish_date;
    for(@contents)
    {
        my $d = $_;
        my $lan = $d->language;
        $data->{'title_' . $lan} = $d->title;
        $data->{'text_' . $lan} = $d->text;
    }
    return $data;
}
sub main_title
{
    my $self = shift;
    my @contents = $self->row->contents->search({ language => config->{default_language} });
    if($contents[0])
    {
        return $contents[0]->title;
    }
    else
    {
        #Should not be possible
        return "*** no title ***";
    }

}
sub get_basic_data
{
    my $self = shift;
    my %data;
    $data{'id'} = $self->get_attr('id');
    $data{'title'} = $self->main_title;
    $data{'category'} = $self->row->category->category;
    $data{'display_order'} = $self->get_attr('display_order');
    $data{'published'} = $self->get_attr('published');
    return %data;
}
sub get_ext_data
{
    my $self = shift;
    my $language = shift;
    my %data;
    %data = $self->get_basic_data();
    $data{'title'} = $self->get_attr_multilang('title', $language);
    $data{'slug'} = $self->get_attr_multilang('slug', $language);
    $data{'text'} = $self->get_attr_multilang('text', $language);
    $data{'display_order'} = $self->get_attr('display_order');
    $data{'publish_date'} = $self->get_attr('publish_date');
    return %data;
}
sub delete
{
    my $self = shift;
    $self->row->delete();
    $self->row->contents->delete_all();
}
sub publish
{
    my $self = shift;
    $self->row->published(1);
    $self->row->update();
}
sub unpublish
{
    my $self = shift;
    $self->row->published(0);
    $self->row->update();
}


sub get_attr
{
    my $self = shift;
    my $attr = shift;
    return $self->row->get_column($attr);
}
sub get_attr_multilang
{
    my $self = shift;
    my $attr = shift;
    my $lang = shift;
    my $content = $self->row->contents->find({'language' => $lang});
    if($content)
    {
        return $content->get_column($attr);
    }
    else
    {
        return undef;
    }
}

#Static helpers

sub get_list
{
    my $params = shift;
    my %args = %{ $params };
    $args{'order'} ||= 'desc';
    $args{'order_by'} ||= 'id';
    $args{'entries_per_page'} ||= 20;
    $args{'page'} ||= 1;
    $args{'language'} ||= config->{default_language};
    my $search_criteria = undef;
    if(exists $args{'published'})
    {
        $search_criteria->{'published'} = $args{'published'};
    }
    my $rs;
    if(exists $args{'category'})
    {
        my $category = schema->resultset('Category')->find( { category => $args{'category'} } );
        $rs = $category->articles->search($search_criteria, { order_by => { '-' . $args{'order'} => $args{'order_by'} } , page => 1, rows => $args{'entries_per_page'} });
    }
    else
    {
        $rs = schema->resultset('Article')->search($search_criteria, { order_by => { '-' . $args{'order'} => $args{'order_by'} } , page => 1, rows => $args{'entries_per_page'}});
    }
    my $pager = $rs->pager();
    my $elements = $rs->page($args{'page'});
    my @to_view;
    for($elements->all())
    {
        my $img = Strehler::Element::Article->new($_->id);
        my %el;
        if(exists $args{'ext'})
        {
            %el = $img->get_ext_data($args{'language'});
        }
        else
        {
            %el = $img->get_basic_data();
        }
        push @to_view, \%el;
    }
    return {'to_view' => \@to_view, 'last_page' => $pager->last_page()};
}


sub save_form
{
    my $id = shift;
    my $form = shift;
    
    my $article_row;
    my $order;
    if($form->param_value('category'))
    {
        $order = $form->param_value('order');
    }
    else
    {
        $order = undef;
    }
    my $article_data ={ image => $form->param_value('image'), category => $form->param_value('category'), display_order => $order, publish_date => $form->param_value('publish_date') };
    if($id)
    {
        $article_row = schema->resultset('Article')->find($id);
        $article_row->update($article_data);
        $article_row->contents->delete_all();
    }
    else
    {
        $article_row = schema->resultset('Article')->create($article_data);
    }
    my @languages = @{config->{languages}};
    for(@languages)
    {
        my $lan = $_;
        if($form->param_value('title_' . $lan) && $form->param_value('text_' . $lan))
        {
            my $slug = $article_row->id . '-' . Strehler::Helpers::slugify($form->param_value('title_' . $lan));
            $article_row->contents->create( { title => $form->param_value('title_' . $lan), text => $form->param_value('text_' . $lan), slug => $slug, language => $lan }) 
        }
    }
    return $article_row->id;  
}


1;







