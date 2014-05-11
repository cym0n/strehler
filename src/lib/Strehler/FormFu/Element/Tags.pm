package Strehler::FormFu::Element::Tags;
use Moose;
extends 'HTML::FormFu::Element::Block';

after BUILD => sub {
    my $self = shift;
    $self->tag("div");
    $self->id("tags-place");
    return;
};

1;

