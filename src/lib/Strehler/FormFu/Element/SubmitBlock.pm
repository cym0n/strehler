package Strehler::FormFu::Element::SubmitBlock;

use strict;
use Moose;

extends 'HTML::FormFu::Element::Fieldset';

after BUILD => sub {
    my $self = shift;
    my $root_path = __FILE__;
    $root_path =~ s/FormFu\/Element\/SubmitBlock\.pm//;
    $self->load_config_file($root_path . "forms/admin/elements/submit_block.yml");
    $self->name("save");
    return;
};

=encoding utf8

=head1 NAME

Strehler::FormFu::Element::SubmitBlock - FormFu Element for Strehler submit buttons.

=head1 DESCRIPTION

Standard Strehler implementation consider two submit buttons: one that redirect to list at the end of the work (Submit) and one that keep you on the edit page after saving the content (Submit and Continue). All the business logic for that is encapsulated in this FormFu element.

Keep in mind that a simple Submit button created in a stardard way will still work, but always with the behaviour of the Submit button of the SubmitBlock. It's mandatory that the submit button (or the block that contains it) has name "save".

=head1 SYNOPSIS

In article form:

    - type: "+Strehler::FormFu::Element::SubmitBlock"

No parameters, no labels.

=head1 GENERATED HTML

    <fieldset>
        <button value="submit-go" type="submit" name="strehl-action" class="btn btn-primary span3">
        Submit
        </button>
        <button value="submit-continue" type="submit" name="strehl-action" class="btn btn-info span3">
        Submit and Continue
        </button>
    </fieldset>

=head1 YAML CONFIGURATION

For the complete configuration see in the package: forms/admin/elements/submit_block.yml

=cut

1;
