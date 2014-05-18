package Strehler::Element::Role::Configured;

use Moo::Role;
use Dancer2;
use Dancer2::Plugin::DBIC;

requires 'metaclass_data'; 

sub category_accessor
{
    my $self = shift;
    my $category = shift;
    return $category->can($self->metaclass_data('category_accessor'));
}

sub item_type
{
    my $self = shift;
    return $self->metaclass_data('item_type');
}

sub ORMObj
{
    my $self = shift;
    return $self->metaclass_data('ORMObj');
}
sub multilang_children
{
    my $self = shift;
    return $self->metaclass_data('multilang_children') || '';
}
sub get_schema
{
    if(config->{'Strehler'}->{'schema'})
    {
        return schema config->{'Strehler'}->{'schema'};
    }
    else
    {
        return schema;
    }
}
sub auto
{
    my $self = shift;
    return config->{'Strehler'}->{'extra_menu'}->{$self->item_type()}->{auto} || 1;
}
sub label
{
    my $self = shift;
    return config->{'Strehler'}->{'extra_menu'}->{$self->item_type()}->{label} || "???";
}
sub class
{
    my $self = shift;
    return return config->{'Strehler'}->{'extra_menu'}->{$self->item_type()}->{class} || 'Strehler::Element';
}
sub creatable
{
     my $self = shift;
     return config->{'Strehler'}->{'extra_menu'}->{$self->item_type()}->{creatable} || 1;
}
sub updatable
{
    my $self = shift;
    return config->{'Strehler'}->{'extra_menu'}->{$self->item_type()}->{updatable} || 1;
}
sub deletable
{
    my $self = shift;
    return config->{'Strehler'}->{'extra_menu'}->{$self->item_type()}->{deletable} || 1;
}
sub categorized
{
    my $self = shift;
    return config->{'Strehler'}->{'extra_menu'}->{$self->item_type()}->{categorized} || 0;
}
sub ordered
{
    my $self = shift;
    return config->{'Strehler'}->{'extra_menu'}->{$self->item_type()}->{ordered} || 0;
}
sub dated
{
    my $self = shift;
    return config->{'Strehler'}->{'extra_menu'}->{$self->item_type()}->{dated} || 0;
}
sub publishable
{
    my $self = shift;
    return config->{'Strehler'}->{'extra_menu'}->{$self->item_type()}->{publishable} || 0,
}
sub custom_list_view
{
    my $self = shift;
    return config->{'Strehler'}->{'extra_menu'}->{$self->item_type()}->{custom_list_view} || undef;
}
sub form
{
    my $self = shift;
    return config->{'Strehler'}->{'extra_menu'}->{$self->item_type()}->{form} || undef;
}
sub multilang_form
{
    my $self = shift;
    return config->{'Strehler'}->{'extra_menu'}->{$self->item_type()}->{multilang_form} || undef;
}
sub allowed_role
{
    my $self = shift;
    if(config->{'Strehler'}->{'extra_menu'}->{$self->item_type()}->{allowed_role})
    {
        return config->{'Strehler'}->{'extra_menu'}->{$self->item_type()}->{allowed_role};
    }
    elsif(config->{'Strehler'}->{'extra_menu'}->{$self->item_type()}->{role}) 
    {
        #For retrocompatibility
        return config->{'Strehler'}->{'extra_menu'}->{$self->item_type()}->{role};
    }
    else
    {
        return undef;
    }
}
sub entity_data
{
    my $self = shift;
    my @attributes = ('auto', 
                   'label', 
                   'class', 
                   'creatable', 
                   'updatable', 
                   'deletable',
                   'categorized',
                   'ordered',  
                   'dated',
                   'publishable',
                   'custom_list_view',
                   'form',
                   'multilang_form',
                   'allowed_role');
    my %entity_data;
    foreach my $attr (@attributes)
    {
        $entity_data{$attr} = $self->$attr();
    }
    return %entity_data;
}



1;
