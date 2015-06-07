package Strehler::FormFu::Validator::UserUnique;

use strict;
use warnings;
use Moose;
use Strehler::Element::User;

use base 'HTML::FormFu::Validator';

sub validate_value {
    my ( $self, $value ) = @_;
    my $user = Strehler::Element::User->get_from_username($value);
    return ! $user;
}

=encoding utf8

=head1 NAME

Strehler::FormFu::Validator::UserUnique - FormFu Validator for User form.

=head1 DESCRIPTION

A FormFu Validator to ensure that a user can't be created with a name already used.

This validator hasn't the standard HTML::FormFu validators namespace because it makes sense only in a Strehler system.

=head1 SYNOPSIS

In user form configuration:

    - name: user
      label: Username
      attributes: 
        class: span8
      validators:
        - type: '+Strehler::FormFu::Validator::UserUnique'
          message: 'Username already exists'
=cut


1;
