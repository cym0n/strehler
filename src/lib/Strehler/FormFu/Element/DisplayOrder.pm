package Strehler::FormFu::Element::DisplayOrder;
use Moose;
extends 'HTML::FormFu::Element::Fieldset';

after BUILD => sub {
    my $self = shift;
    my $root_path = __FILE__;
    $root_path =~ s/FormFu\/Element\/DisplayOrder\.pm//;
    $self->load_config_file($root_path . "forms/admin/elements/display_order.yml");
    return;
};

1;
