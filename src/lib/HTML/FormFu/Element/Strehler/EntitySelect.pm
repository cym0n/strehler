package HTML::FormFu::Element::Strehler::EntitySelect;
use Moose;
extends 'HTML::FormFu::Element::Select';

use Data::Dumper;
use Carp qw( croak );

has _element => (
    is => 'rw',
    default => sub { [] },
    lazy => 1,
);

after BUILD => sub {
    my $self = shift;

    $self->filename('input');
    $self->field_filename('select_tag');
    $self->multi_value(1);
    
    return;
};

sub element {
    my ( $self, $arg ) = @_;

    return $self->_element if @_ == 1;


    if ( defined $arg ) {


        $self->_element( $arg);
        eval "require $arg";
        $self->options($arg->make_select());
    }
    return $self;
}

1;
