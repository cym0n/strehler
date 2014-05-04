package Strehler::FormFu::Element::Category;
use Moose;
extends 'HTML::FormFu::Element::Block';

after BUILD => sub {
    my $self = shift;
    my $root_path = __FILE__;
    $root_path =~ s/FormFu\/Element\/Category\.pm//;
    $self->load_config_file($root_path . "forms/admin/elements/category.yml");
    $self->name("categoryblock");
    return;
};

1;
