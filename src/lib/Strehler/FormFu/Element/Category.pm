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

=encoding utf8

=head1 NAME

Strehler::FormFu::Element::Category - FormFu Element for Strehler Category Selector.

=head1 DESCRIPTION

A FormFu element to encapsulate all the frontend logic for category selection. It's just a Block element with a particular configuration file hard-coded in it.
Category selector needs to be identified in a clear way and needs a fixed structure because it has to interact with Strehler javascript library.

This element hasn't the standard HTML::FormFu elements namespace because it makes sense only in a Strehler system.

=head1 SYNOPSIS

In article form:

    - type: "+Strehler::FormFu::Element::Category"

No parameters, no labels.

=head1 GENERATED HTML

    <div>
        <div>
            <label for="category_selector">Category</label>
            <select id="category_selector" name="category">
                <option value="">-- select --</option>
                <option value="1">cat1</option>
                <option value="2">cat2</option>
            </select>
        </div>
        <div style="display: none;">
            <label for="subcat">Sub-category</label>
            <select id="subcat" name "subcategory">
                <option value="">-- select --</option>
                <option value="10">subcat1</option>
                <option value="11">subcat2</option>
            </select>
        </div>
    </div>

Options are inserted dinamically during form generation.
Sub-category display attributed is managed by javascript.

=head1 YAML CONFIGURATION

For the complete configuration see in the package: _forms/admin/elements/category.yml_

=cut

1;
