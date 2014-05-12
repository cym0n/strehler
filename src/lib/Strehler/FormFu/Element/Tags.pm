package Strehler::FormFu::Element::Tags;
use Moose;
extends 'HTML::FormFu::Element::Block';

after BUILD => sub {
    my $self = shift;
    $self->tag("div");
    $self->id("tags-place");
    return;
};

=encoding utf8

=head1 NAME

Strehler::FormFu::Element::Tags - FormFu Element for Strehler tags field.

=head1 DESCRIPTION

A FormFu element to encapsulate all the frontend logic for tags field. It's just a Block element with tag and id hardcoded in it.
Tags field needs to be identified in a clear way and needs a fixed structure because it has to interact with Strehler javascript library.

This element hasn't the standard HTML::FormFu elements namespace because it makes sense only in a Strehler system.

=head1 SYNOPSIS

In article form:

    - type: "+Strehler::FormFu::Element::Tags"

No parameters, no labels.

=head1 GENERATED HTML

    <div id="tags-place"><label for="tags">Tags</label>
        <input type="text" name="tags">
    </div>

=head1 YAML CONFIGURATION

    - type: Block
      tag: div
      id: tags-place


=cut

1;

