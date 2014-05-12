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

=encoding utf8

=head1 NAME

Strehler::FormFu::Element::DisplayOrder - FormFu Element for Strehler Display order field.

=head1 DESCRIPTION

A FormFu element to encapsulate all the frontend logic for display order field with "Next!" button. It's just a Fieldset element with a particular configuration file hard-coded in it.
Display order field needs to be identified in a clear way and needs a fixed structure because it has to interact with Strehler javascript library.

This element hasn't the standard HTML::FormFu elements namespace because it makes sense only in a Strehler system.

=head1 SYNOPSIS

In article form:

    - type: "+Strehler::FormFu::Element::DisplayOrder"

No parameters, no labels.

=head1 GENERATED HTML

    <fieldset class="order-widget">
        <div>
            <label for="order">Order</label>
            <input type="text" id="order" value="2" name="display_order">
        </div>
        <button type="button" id="last" class="btn btn-warning">
            Next!
        </button>
    </fieldset>


=head1 YAML CONFIGURATION

For the complete configuration see in the package: _forms/admin/elements/display_order.yml_

=cut

1;
