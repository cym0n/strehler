package Strehler::Element::Log;

use strict;
use Moo;
use Dancer2 0.154000;
use Dancer2::Plugin::DBIC;
use DateTime::Format::Strptime;

extends 'Strehler::Element';

#Standard element implementation

my $root_path = __FILE__;
$root_path =~ s/Log\.pm//;
my $form_path = $root_path . "../forms";
my $views_path = $root_path . "../views";

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
    my $self = shift;
    return $self->_property('exposed', 0);
}
sub label
{
    my $self = shift;
    return $self->_property('label', 'Logs');
}
sub creatable
{
    my $self = shift;
    return $self->_property('creatable', 0);
}
sub updatable
{
    my $self = shift;
    return $self->_property('updatable', 0);
}
sub deletable
{
    my $self = shift;
    return $self->_property('deletable', 0);
}
sub allowed_role
{
    my $self = shift;
    return $self->_property('allowed_role', 'admin');
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
sub custom_list_template
{
    return $views_path . "/admin/entities/log_list_block.tt";
}

sub install
{
    return "Standard entity. No installation is needed.";
}



=encoding utf8

=head1 NAME

Strehler::Element::Log - Strehler Entity for logs

=head1 DESCRIPTION

A little entity used to log Strehler backend actions and keep trace of it.

=cut

1;

