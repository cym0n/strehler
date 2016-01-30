package Strehler::Element::Image;

use strict;
use Cwd 'abs_path';
use Moo;
use Dancer2 0.166001;
use Dancer2::Plugin::DBIC;

extends 'Strehler::Element';

my $module_file_path = __FILE__;
my $root_path = abs_path($module_file_path);
$root_path =~ s/Image\.pm//;
my $form_path = $root_path . "../forms";
my $views_path = $root_path . "../views";

#Standard element implementation

sub metaclass_data 
{
    my $self = shift;
    my $param = shift;
    my %element_conf = ( item_type => 'image',
                         ORMObj => 'Image',
                         category_accessor => 'images',
                         multilang_children => 'descriptions' );
    return $element_conf{$param};
}

#Standard configuration overrides

sub label
{
    my $self = shift;
    return $self->_property('label', 'Images');
}
sub categorized
{
    my $self = shift;
    return $self->_property('categorized', 1);
}

sub class
{
    return __PACKAGE__;
}
sub form
{
    return $form_path . '/admin/image.yml';
}
sub multilang_form
{
    return $form_path . '/admin/image_multilang.yml';
}


#Main title redefined to fetch title from multilang attributes
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
sub fields_list
{
    my $self = shift;
    my @fields = ( { 'id' => 'id',
                     'label' => 'ID',
                     'ordinable' => 1 },
                   { 'id' => 'descriptions.title',
                     'label' => 'Title',
                     'ordinable' => 1 },
                   { 'id' => 'category',
                       'label' => 'Category',
                       'ordinable' => 0 },
                   { 'id' => 'Preview',
                       'label' => 'Preview',
                       'ordinable' => 0 }
               );
    return \@fields;
    
}

#Save form redefined to manage image upload
sub save_form
{
    my $self = shift;
    my $id = shift;
    my $form = shift;
    my $uploads = shift;
        
    my $img = $uploads->{'photo'};
    my $ref; 
    my $path;
    my $public;
    
    if($img)
    {
        $public = Strehler::Helpers::public_directory();
        $ref = '/upload/' . $img->filename;
        $path = $public . $ref;
        $img->copy_to($path);
    }
    
    my $category;
    if($form->param_value('category'))
    {
        $category = $form->param_value('category');
    }
    
    my $img_row;
    if($id)
    {
        $img_row = $self->get_schema()->resultset('Image')->find($id);
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
        $img_row = $self->get_schema()->resultset('Image')->create({ image => $ref, category => $category });
    }
    my @languages = @{config->{Strehler}->{languages}};
    for(@languages)
    {
        my $lan = $_;
        $img_row->descriptions->create( { title => $form->param_value('title_' . $lan), description => $form->param_value('description_' . $lan), language => $lan }) if($form->param_value('title_' . $lan) || $form->param_value('description_' . $lan));;
    }
    Strehler::Meta::Tag->save_tags($form->param_value('tags'), $img_row->id, 'image');
    return $img_row->id;     
}
sub search_box
{
    my $self = shift;
    my $string = shift;
    my $parameters = shift;
    $parameters->{'search'} = { 'descriptions.title' => { 'like', "%$string%" } };
    $parameters->{'join'} = 'descriptions';
    return $self->get_list($parameters);
}

sub custom_add_snippet
{
    my $self = shift;
    if(ref($self))
    {
        return "<p>Image:</p>" .
               '<img class="span2" src=' . $self->get_attr('image') . " />"; 
    }
    else
    {
        return undef;
    }
}

sub custom_list_template
{
    return $views_path . "/admin/entities/image_list_block.tt";
}

sub install
{
    return "Standard entity. No installation is needed.";
}

=encoding utf8

=head1 NAME

Strehler::Element::Image - Strehler Entity for images

=head1 DESCRIPTION

Base Strehler content, it's used to create images, multilanguage.

Its main title is the title in the language configured as default.

It has all the features of base Strehler::Element plus the capability to upload images.

=cut 

1;







