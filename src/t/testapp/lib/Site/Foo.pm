package Site::Foo;

use Moo;
use Dancer2;

extends 'Strehler::Element';
with 'Strehler::Element::Role::Slugged';

sub metaclass_data 
{
    my $self = shift;
    my $param = shift;
    my %element_conf = ( item_type => 'foo',
                         ORMObj => 'foos',
                         category_accessor => 'foos',
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

sub categorized
{
    return 1;
}
1;
