package Strehler::Element::Log;

use Moo;
use Dancer2 0.11;
use Dancer2::Plugin::DBIC;
use DateTime::Format::Strptime;

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

#Standard configuration overrides
sub exposed
{
    return config->{'Strehler'}->{'extra_menu'}->{'log'}->{exposed} || 0;
}
sub label
{
    return config->{'Strehler'}->{'extra_menu'}->{'log'}->{label} || "Logs";
}
sub creatable
{
    return config->{'Strehler'}->{'extra_menu'}->{'log'}->{creatable} || 0;
}
sub updatable
{
    return config->{'Strehler'}->{'extra_menu'}->{'log'}->{updatable} || 0;
}
sub deletable
{
    return config->{'Strehler'}->{'extra_menu'}->{'log'}->{deletable} || 0;
}
sub custom_list_view
{
    return config->{'Strehler'}->{'extra_menu'}->{'log'}->{custom_list_view} || 'admin/log_list';
}
sub allowed_role
{
    if(config->{'Strehler'}->{'extra_menu'}->{'log'}->{allowed_role})
    {
        return config->{'Strehler'}->{'extra_menu'}->{'log'}->{allowed_role};
    }
    elsif(config->{'Strehler'}->{'extra_menu'}->{'log'}->{role}) 
    {
        #For retrocompatibility
        return config->{'Strehler'}->{'extra_menu'}->{'log'}->{role};
    }
    else
    {
        return 'admin';
    }
}
sub class
{
    return __PACKAGE__;
}

sub write
{
    my $self = shift;
    my $user = shift;
    my $action = shift;
    my $entity_type = shift;
    my $entity_id = shift;
    my $log_row = $self->get_schema()->resultset($self->ORMObj())->create({ user => $user, action => $action, entity_type => $entity_type, entity_id => $entity_id, timestamp => DateTime->now() });
}

sub main_title
{
    my $self = shift;
    return "[" . $self->get_attr('timestamp') . "] " . $self->get_attr('action') . " " . $self->get_attr('entity_type');
}

sub fields_list
{
    my $self = shift;
    my @fields = ( { 'id' => 'id',
                     'label' => 'ID',
                     'ordinable' => 1 },
                   { 'id' => 'timestamp',
                     'label' => 'Timestamp',
                     'ordinable' => 1 },
                   { 'id' => 'user',
                       'label' => 'User',
                       'ordinable' => 1 },
                   { 'id' => 'action',
                       'label' => 'Action',
                       'ordinable' => 0 },
                   { 'id' => 'object',
                       'label' => 'Object',
                       'ordinable' => 0 }
               );
    return \@fields;
    
}


=encoding utf8

=head1 NAME

Strehler::Element::Log - Strehler Entity for logs

=head1 DESCRIPTION

A little entity used to log Strehler backend actions and keep trace of it.

=cut

1;

