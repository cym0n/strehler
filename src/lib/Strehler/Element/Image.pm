package Strehler::Element::Image;

use Moo;
use Dancer2;
use Dancer2::Plugin::DBIC;
use Data::Dumper;

extends 'Strehler::Element';


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
    $data->{'tags'} = Strehler::Meta::Tag::tags_to_string($self->get_attr('id'), 'image');
    return $data;
}
sub main_title
{
    my $self = shift;
    my @desc = $self->row->descriptions->search({ language => config->{Strehler}->{default_language } });
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
sub src
{
    my $self = shift;
    #just a wrapper for templates
    return $self->get_attr('image');
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

sub category_accessor
{
    my $self = shift;
    my $category = shift;
    return $category->can('images');
}

sub item_type
{
    return "image";
}
sub ORMObj
{
    return "Image";
}
sub multilang_children
{
    return "descriptions";
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
    my @languages = @{config->{Strehler}->{languages}};
    for(@languages)
    {
        my $lan = $_;
        $img_row->descriptions->create( { title => $form->param_value('title_' . $lan), description => $form->param_value('description_' . $lan), language => $lan }) if($form->param_value('title_' . $lan) || $form->param_value('description_' . $lan));;
    }
    Strehler::Meta::Tag::save_tags($form->param_value('tags'), $img_row->id, 'image');
    return $img_row->id;     
}


1;







