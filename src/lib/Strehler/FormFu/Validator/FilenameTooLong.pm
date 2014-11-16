package Strehler::FormFu::Validator::FilenameTooLong;

use strict;
use warnings;
use Moose;
use Strehler::Meta::Category;

use base 'HTML::FormFu::Validator';

sub validate_value {
    my ( $self, $value ) = @_;
    return length $value < 50;
}

=encoding utf8

=head1 NAME

Strehler::FormFu::Validator::FilenameTooLong - FormFu Validator for File field in image form.

=head1 DESCRIPTION

A FormFu Validator to ensure that a user can't load an image with a name longer than 50 characters using the Image entity.

Images are not renamed when loaded in Strehler and their names are saved in the database. Database field for image name can't afford names longer than 50 characters.

This validator could be loaded using FormFu namespace, but for now I'll keep it in the Strehler distribution.

=head1 SYNOPSIS

In image form configuration:

    elements:
        - type: File
          name: photo
          label: Image
          attributes: 
            class: span5
          validators:
            - type: '+Strehler::FormFu::Validator::FilenameTooLong'
              message: 'Filename is too long'

=cut


1;
