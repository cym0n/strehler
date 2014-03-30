package Strehler::FormFu::Validator::CategoryUnique;

use strict;
use warnings;
use Moose;
use Strehler::Meta::Category;

use base 'HTML::FormFu::Validator';

sub validate_value {
    my $self = shift;
    my $query = $self->form->query();
    my $parent = $query->param('parent');
    my $category = $query->param('category');
    my $prev_parent = $query->param('prev-parent') || "";
    my $prev_name = $query->param('prev-name') || "";
    my $category_name;
    if($parent eq $prev_parent && $category eq $prev_name)
    {
        return 1;
    }
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

=encoding utf8

=head1 NAME

Strehler::FormFu::Validator::CategoryUnique - FormFu Validator for Category form.

=head1 DESCRIPTION

A FormFu Validator to ensure that a user can't insert a category with the same name of a category already inserted.
Parent value of the form must be checked because two category with the same name under different parents can exist.

This validator hasn't the standard HTML::FormFu validators namespace because it makes sense only in a Strehler system.

=head1 SYNOPSIS

In category form configuration:

    - name: category
      label: Category
      constraints:
        - type: Required
          message: 'Category needed'
        - type: Regex
          regex: '^[^\/]*$'
          message: 'Invalid character'
      validators:
        - type: '+Strehler::FormFu::Validator::CategoryUnique'
          message: 'Category already exists'

=cut

1;
