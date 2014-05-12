package Strehler::FormFu::Element::PublishDate;
use Moose;
extends 'HTML::FormFu::Element::Text';

after BUILD => sub {
    my $self = shift;
    $self->name("publish_date");
    $self->label("Date");
    $self->id("date_of_pub");
    $self->inflator({ type => "DateTime", parser => { strptime => "%d/%m/%Y"}});
    $self->deflator({ type => "Strftime", strftime => "%d/%m/%Y"});
    return;
};

=encoding utf8

=head1 NAME

Strehler::FormFu::Element::PublishDate - FormFu Element for Strehler publish date field.

=head1 DESCRIPTION

A FormFu element to encapsulate all the frontend logic for publish date field. It's just a text element with html attributes, inflator and deflator hard-coded in it.
Publish date field needs to be identified in a clear way and needs a fixed structure because it has to interact with bootstrap datepicker.

This element hasn't the standard HTML::FormFu elements namespace because it makes sense only in a Strehler system.

=head1 SYNOPSIS

In article form:

    - type: "+Strehler::FormFu::Element::PublishDate"

No parameters, no labels.

=head1 GENERATED HTML

    <div>
        <label for="date_of_pub">Date</label>
        <input type="text" id="date_of_pub" name="publish_date">
    </div>

=head1 YAML CONFIGURATION

    - id: date_of_pub
      name: publish_date
      label: Date
      inflators:
         - type: DateTime
           parser:
              strptime: "%d/%m/%Y"
      deflator:
         - type: Strftime
           strftime: "%d/%m/%Y"

=cut



1;
