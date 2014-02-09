package HTML::FormFu::Validator::Strehler::CategoryUnique;

use strict;
use warnings;
use Moose;
use Data::Dumper;
use Strehler::Meta::Category;


use base 'HTML::FormFu::Validator';

sub validate_value {
    my $self = shift;
    my $parent = $self->form->param_value('parent');
    my $category = $self->form->param_value('category');
    my $category_name;
    if($parent)
    {
        my $parent_element = Strehler::Meta::Category->new($parent);
        $category_name = $parent_element->get_attr('category') . '/' . $category;
    }
    else
    {
        $category_name = $category;
    }
    my $category_element = Strehler::Meta::Category->explode_name($category_name);
    return ! $category_element->exists();
}

1;
