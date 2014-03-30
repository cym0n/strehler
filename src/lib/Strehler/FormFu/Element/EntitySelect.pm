package Strehler::FormFu::Element::EntitySelect;
use Moose;
extends 'HTML::FormFu::Element::Select';

use Carp qw( croak );

has _element => (
    is => 'rw',
    default => sub { [] },
    lazy => 1,
);

after BUILD => sub {
    my $self = shift;

    $self->filename('input');
    $self->field_filename('select_tag');
    $self->multi_value(1);
    
    return;
};

sub element {
    my ( $self, $arg ) = @_;

    return $self->_element if @_ == 1;


    if ( defined $arg ) {


        $self->_element( $arg);
        eval "require $arg";
        $self->options($arg->make_select());
    }
    return $self;
}

=encoding utf8

=head1 NAME

Strehler::FormFu::Element::EntitySelect - FormFu Element to allow browsing a Strehler entity with a select box.

=head1 DESCRIPTION

A Strehler element that you can include in your form configuration to add in an entity edit form a select box populated with the elements of another entity, tipically to manage a foreign key field.

This element hasn't the standard HTML::FormFu validators namespace because it makes sense only in a Strehler system.

=head1 SYNOPSIS

In  custom Strehler entity form:

    - type: '+Strehler::FormFu::Element::EntitySelect'
      name: otherentity
      label: Entity
      element: Site::Element::MyEntity

=head1 PARAMETERS

=over 4

=item element

A module derived from Strehler::Element, usually another object managed in Strehler backend. You can use standard entitites (Strehler::Element::Article or Strehler::Element::Image) as well.

=back

=cut

1;
