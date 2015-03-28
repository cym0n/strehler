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

1;
