package Strehler::FormFu::Element::Slug;

use Moose;
extends 'HTML::FormFu::Element::Label';

after BUILD => sub {
    my $self = shift;
    $self->name("slug");
    $self->label("Slug [Automatic]");
    $self->default("...");
    $self->attributes({'class' => 'span8 slug'});
    return;
};

=encoding utf8

=head1 NAME

Strehler::FormFu::Element::Slug - FormFu Element for Strehler slug field.

=head1 DESCRIPTION

A formfu field to show slug in slugged entities. It's a read-only field because slug is automatically managed.

=head1 SYNOPSIS

In article form:

    - type: "+Strehler::FormFu::Element::Slug"

No parameters, no labels.

=head1 GENERATED HTML

    <div>
        <label>Slug [Automatic]</label>
        <span name="slug" class="span8 slug">99-lorem-ipsum</span>
    </div>   

=head1 YAML CONFIGURATION

    - name: slug
      label: "Slug [Automatic]"
      type: label
      attributes:
        class: "span8 slug"
        
=cut



1;
