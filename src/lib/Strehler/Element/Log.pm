package Strehler::Element::Log;

use Moo;
use Dancer2;
use Dancer2::Plugin::DBIC;

extends 'Strehler::Element';

#Standard element implementation

sub metaclass_data 
{
    my $self = shift;
    my $param = shift;
    my %element_conf = ( item_type => 'log',
                         ORMObj => 'ActivityLog',
                         category_accessor => '',
                         multilang_children => '' );
    return $element_conf{$param};
}


sub write
{
    my $self = shift;
    my $user = shift;
    my $action = shift;
    my $entity_type = shift;
    my $entity_id = shift;
    my $log_row = schema->resultset($self->ORMObj())->create({ user => $user, action => $action, entity_type => $entity_type, entity_id => $entity_id });
}

1;

