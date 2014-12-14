package Site::Puppet;

use Moo;
use Dancer2;

extends 'Strehler::Element';
with 'Strehler::Element::Role::Slugged';

sub metaclass_data 
{
    my $self = shift;
    my $param = shift;
    my %element_conf = ( item_type => 'puppet',
                         ORMObj => 'Puppet',
                         category_accessor => undef,
                         multilang_children => undef );
    return $element_conf{$param};
}

sub to_slug
{
    my $self = shift;
    my $lan = shift;
    return 'text';
}

sub multilang_slug
{
    return 0;
}
1;
