package Site::Dummy;

use Moo;
use Dancer2;

extends 'Strehler::Element';

sub metaclass_data 
{
    my $self = shift;
    my $param = shift;
    my %element_conf = ( item_type => 'dummy',
                         ORMObj => 'Dummy',
                         category_accessor => 'dummies',
                         multilang_children => undef );
    return $element_conf{$param};
}

1;
