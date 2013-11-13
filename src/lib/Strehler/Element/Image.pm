package Strehler::Element::Image;

use Moo;
use Dancer2;
use Dancer2::Plugin::DBIC;
use Strehler::Element::Tag; # qw(save_tags tags_to_string);
use Data::Dumper;

has row => (
    is => 'ro',
);

sub BUILDARGS {
   my ( $class, @args ) = @_;
   my $id = shift @args; 
   my $img_row = schema->resultset('Image')->find($id);
   return { row => $img_row };
};

sub get_form_data
{
    my $self = shift;
    my $img_row = $self->row;
    my @descriptions = $img_row->descriptions;
    my $data;
    if($img_row->category->parent_category)
    {
        $data->{'category'} = $img_row->category->parent_category->id;
        $data->{'subcategory'} = $img_row->category->id;
    }
    else
    {
       $data->{'category'} = $img_row->category->id;
    }
    for(@descriptions)
    {
        my $d = $_;
        my $lan = $d->language;
        $data->{'title_' . $lan} = $d->title;
        $data->{'description_' . $lan} = $d->description;
    }
    $data->{'tags'} = Strehler::Element::Tag::tags_to_string($self->get_attr('id'), 'image');
    return $data;
}
sub main_title
{
    my $self = shift;
    my @desc = $self->row->descriptions->search({ language => config->{default_language } });
    if($desc[0])
    {
        return $desc[0]->title;
    }
    else
    {
        return "*** no title ***";
    }
}
sub get_basic_data
{
    my $self = shift;
    my %data;
    $data{'id'} = $self->get_attr('id');
    $data{'title'} = $self->main_title;
    $data{'source'} = $self->get_attr('image');
    $data{'category'} = $self->row->category->category;
    return %data;
}
sub get_tags
{
    my $self = shift;
    return Strehler::Element::Tag::tags_to_string($self->get_attr('id'), 'image');
}
sub src
{
    my $self = shift;
    #just a wrapper for templates
    return $self->get_attr('image');
}
sub delete
{
    my $self = shift;
    $self->row->delete();
    $self->row->descriptions->delete_all();
}

sub get_attr
{
    my $self = shift;
    my $attr = shift;
    return $self->row->get_column($attr);
}

#Static helpers

sub make_select
{
    my @images_values = schema->resultset('Image')->all();
    my @images_values_for_select;
    push @images_values_for_select, { value => undef, label => "Seleziona immagine..."};
    for(@images_values)
    {
        my $img = Strehler::Element::Image->new($_->id);
        push @images_values_for_select, { value => $_->id, label => $img->main_title() }
    }
    return \@images_values_for_select;
}

sub get_list
{
    my $params = shift;
    my %args = %{ $params };
    $args{'order'} ||= 'desc';
    $args{'order_by'} ||= 'id';
    $args{'entries_per_page'} ||= 20;
    $args{'page'} ||= 1;
    
    my $no_paging = 0;
    my $default_page = 1;
    if($args{'entries_per_page'} == -1)
    {
        $args{'entries_per_page'} = undef;
        $default_page = undef;
        $no_paging = 1;
    }

    my $search_criteria = undef;

    #Images have no publish logic
    #if(exists $args{'published'})
    #{
    #    $search_criteria->{'published'} = $args{'published'};
    #}
    if(exists $args{'tag'} && $args{'tag'})
    {
        my $ids = schema->resultset('Tag')->search({tag => $args{'tag'}, item_type => 'image'})->get_column('item_id');
        $search_criteria->{'id'} = { -in => $ids->as_query };
    }
    my $rs;
    if(exists $args{'category_id'} && $args{'category_id'})
    {
        my $category = schema->resultset('Category')->find( { id => $args{'category_id'} } );
        if(! $category)
        {
            return {'to_view' => [], 'last_page' => 1 };
        }
        $rs = $category->images->search($search_criteria, { order_by => { '-' . $args{'order'} => $args{'order_by'} } , page => $default_page, rows => $args{'entries_per_page'} });
    }
    elsif(exists $args{'category'} && $args{'category'})
    {
       my $category;
       my $category_obj = Strehler::Element::Category::explode_name($args{'category'});
       if(! $category_obj->exists())
       {
           return {'to_view' => [], 'last_page' => 1 };
       }
       else
       {
           $category = $category_obj->row;
       }
       $rs = $category->images->search($search_criteria, { order_by => { '-' . $args{'order'} => $args{'order_by'} } , page => $default_page, rows => $args{'entries_per_page'} });
    }
    else
    {
        $rs = schema->resultset('Image')->search($search_criteria, { order_by => { '-' . $args{'order'} => $args{'order_by'} } , page => $default_page, rows => $args{'entries_per_page'}});
    }
    my $elements;
    my $last_page;
    if($no_paging)
    {
        $elements = $rs;
        $last_page = 1;
    }
    else
    {
        my $pager = $rs->pager();
        $elements = $rs->page($args{'page'});
        $last_page = $pager->last_page();
    }
    my @to_view;
    for($elements->all())
    {
        my $img = Strehler::Element::Image->new($_->id);
        my %el = $img->get_basic_data();
        push @to_view, \%el;
    }
    return {'to_view' => \@to_view, 'last_page' => $last_page};
}
sub exists
{
    my $self = shift;
    if($self->row)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}
sub save_form
{
    my $id = shift;
    my $img = shift;
    my $form = shift;
        
    my $ref; 
    my $path;
    if($img)
    {
        $ref = '/upload/' . $img->filename;
        $path = 'public' . $ref;
        $img->copy_to($path);
    }
    my $category;
    if($form->param_value('subcategory'))
    {
        $category = $form->param_value('subcategory');
    }
    elsif($form->param_value('category'))
    {
        $category = $form->param_value('category');
    }
    my $img_row;

    if($id)
    {
        $img_row = schema->resultset('Image')->find($id);
        if($img)
        {
            $img_row->update({ image => $ref, category => $category });
        }
        else
        {
            $img_row->update({ category => $category });
        }
        $img_row->descriptions->delete_all();
    }
    else
    {
        $img_row = schema->resultset('Image')->create({ image => $ref, category => $category });
    }
    my @languages = @{config->{languages}};
    for(@languages)
    {
        my $lan = $_;
        $img_row->descriptions->create( { title => $form->param_value('title_' . $lan), description => $form->param_value('description_' . $lan), language => $lan }) if($form->param_value('title_' . $lan) || $form->param_value('description_' . $lan));;
    }
    Strehler::Element::Tag::save_tags($form->param_value('tags'), $img_row->id, 'image');
    return $img_row->id;     
}


1;







