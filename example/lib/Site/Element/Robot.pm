package Site::Element::Robot;

use Moo;
use Dancer2;

extends 'Strehler::Element';



sub metaclass_data 
{
    my $self = shift;
    my $param = shift;
    my %element_conf = ( item_type => 'robot',
                         ORMObj => 'Robot',
                         category_accessor => 'robots',
                         multilang_children => 'robots_multis' );
    return $element_conf{$param};
}




1;
