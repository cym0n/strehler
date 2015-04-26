package Strehler::FormFu::Element::SubmitBlockMulti;

use strict;
use Moose;

extends 'HTML::FormFu::Element::Fieldset';

has _actions => (
    is => 'rw',
    default => sub { [] },
    lazy => 1,
);

after BUILD => sub {
    my $self = shift;
    $self->name("save");
    return;
};

sub actions {
    my ( $self, $arg ) = @_;

    return $self->_label if @_ == 1;

    if ( defined $arg ) {
        my @actions = @{$arg};
        my $length;
        if($#actions == 2) 
        {
            $length = 2;
        }
        elsif($#actions < 2)
        {
            $length = 3;
        }
        my $index = 1;
        foreach my $b (@actions)
        {
            $self->element($self->button_conf($b, $index, $length));
            $index++;
        }
    }
    return $self;
}


sub button_conf
{
    my $self = shift;
    my $action = shift;
    my $index = shift;
    my $length = shift;

    my %labels = ( 'submit-go' => 'Submit',
                'submit-continue' => 'Submit and Continue',
                'submit-publish' => 'Submit and Publish');

    #YAML: 
    #name: savebutton1
    #tag: button
    #content: Submit
    #attributes:
        #name: strehl-action
        #value: submit-go
        #type: submit
        #class: btn btn-primary span3 
 
    my $conf;
    $conf->{'type'} = 'Block';
    $conf->{'name'} = 'savebutton' . $index;
    $conf->{'tag'} = 'button';
    $conf->{'content'} = $labels{$action};
        my $attributes;
        $attributes->{'name'} = 'strehl-action';
        $attributes->{'value'} = $action;
        $attributes->{'type'} = 'submit';
        $attributes->{'class'} = 'btn btn-primary span' . $length;
    $conf->{'attributes'} = $attributes;
    return $conf;
}

=encoding utf8

=head1 NAME

Strehler::FormFu::Element::SubmitBlockMulti - FormFu Element for Strehler generic submit buttons.

=head1 DESCRIPTION

Extension for L<Strehler::FormFu::Element::SubmitBlock>.

Allow configurations with one, two or three buttons, chosen from the actions available in Strehler forms:

=over 4

=item

submit-go: submit and return to list page

=item

submit-continue: submit and stay on the edit page

=item

submit-publish: submit and return to list page publishing the content

=back

=head1 SYNOPSIS

In article form:

    - type: "+Strehler::FormFu::Element::SubmitBlockMulti"

=head1 PARAMETERS

=over 4

=item actions

A list of actions. Each action will be a button.

=back

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

There isn't a YAML configuration. Button configuration is hard-coded in the class

=cut

1;
