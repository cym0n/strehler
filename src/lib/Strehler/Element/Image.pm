package Strehler::Element::Image;

use Moo;
use Dancer2;
use Dancer2::Plugin::DBIC;
use Data::Dumper;

extends 'Strehler::Element';

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

#Save form redefined to manage image upload
sub save_form
{
    my $self = shift;
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
    Strehler::Meta::Tag->save_tags($form->param_value('tags'), $img_row->id, 'image');
    return $img_row->id;     
}


1;







