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

1;
