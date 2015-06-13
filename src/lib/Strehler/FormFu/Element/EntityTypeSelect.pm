package Strehler::FormFu::Element::EntityTypeSelect;

use strict;
use Moose;
use Strehler::Helpers;
use Data::Dumper;

extends 'HTML::FormFu::Element::Select';

use Carp qw( croak );

has _excluded => (
    is => 'rw',
    default => sub { [] },
    lazy => 1,
);

after BUILD => sub {
    my $self = shift;

    $self->filename('input');
    $self->field_filename('select_tag');
    $self->multi_value(1);
    $self->generate_options(undef);
    return;
};

sub excluded { ## no critic qw(Subroutines::RequireArgUnpacking)
    my ( $self, $arg ) = @_;

    return $self->_element if @_ == 1;

 
    if ( defined $arg ) {
        $self->generate_options($arg);
    }
    return $self;
}

sub generate_options
{
    my $self = shift;
    my $excluded = shift;
    my %blacklist = ();
    %blacklist = map { $_ => 1 } @{$excluded} if $excluded;
    my @entities = Strehler::Helpers::entities_list();
    my @elements_of_select;
    push @elements_of_select, { value => undef, label => "-- select --"};
    foreach my $e (@entities)
    {
        if(! exists $blacklist{$e})
        {
            my $c = Strehler::Helpers::class_from_entity($e);
            push @elements_of_select, { value => $e, label => $c->label() }
        }
    }
    $self->options(\@elements_of_select);

    return;
}

=encoding utf8

=head1 NAME

Strehler::FormFu::Element::EntityTypeSelect - FormFu Element to allow to select a Strehler entity.

=head1 DESCRIPTION

A Strehler element that you can include in your form configuration to allow user to select a Strehler entity.

This element hasn't the standard HTML::FormFu elements namespace because it makes sense only in a Strehler system.

=head1 SYNOPSIS

In  custom Strehler entity form:

    - type: '+Strehler::FormFu::Element::EntityTypeSelect'
      name: entitytype
      label: Entity Type
      excluded: [ 'log', 'image' ]

=head1 PARAMETERS

=over 4

=item excluded

Entities that you don't want to be listed in the select. For example, to avoid Strehler admin entities to be listed:

    excluded: ['log', 'user']

=back

=cut

1;
