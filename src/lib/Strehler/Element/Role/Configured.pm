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

sub data_fields
{
    return undef;
}

sub multilang_data_fields
{
    return undef;
}
=encoding utf8

=head1 NAME

Strehler::Element::Role::Configured - Configuration role

=head1 DESCRIPTION

This role is used by Strehler elements to declare their configuration.

Every "flag function" just read the role value from Dancer2 config.yml.

Creating new entities you can set their flags in config.yml or override Configured role's functions.

Overriding functions has priority on config.yml.

=head1 FUNCTIONS

=over 4

=item category_accessor

arguments: $category

retur value: $accessor

Return the category accessor used by category module to reference the categorized module.

(Value is defined using metaclass_data function)

=item item_type

retur value: $item_type

Return the type of the item

(Value is defined using metaclass_data function)

=item ORMObj

retur value: $ORMObj

Return the name of the DBIx::Class Module controlled by the element.

(Value is defined using metaclass_data function)

=item multilang_children

return value: $accessor_name

Return the name of the accessor used by DBIX::Class module to reference multilang children rows

(Value is defined using metaclass_data function)

=item get_schema

return $schema

Wrapper for Dancer2 schema keyword, used internally to allow developer to use a different schema from default for Strehler

=item "flag functions"

=over 6

=item *

auto

=item *

label

=item *

class

=item *

creatable

=item *

updatable

=item *

deletable

=item *

categorized

=item *

ordered

=item *

dated

=item *

publishable

=item *

custom_list_view

=item *

form

=item *

multilang_form

=item *

allowed_role

=back

All these functions read from configuration file status of the property. They can be overriden to configure different values for properties in custom element with non configuration file involvement.

For the meaning of every flag see L<Strehler::Manual::ExtraEntityConfiguration>

=item get_schema

return $schema

Wrapper for Dancer2 schema keyword, used internally to allow developer to use a different schema from default for Strehler

=item entity_data

return %data

Return all the configuration for an element as an hash

=item data_fields

return undef

This method can be overriden to give back different fields from the database columns in get_basic_data function.

In a custom element make it return an array of strings.

WARNING: behaviour unpredictable if any string is not a database column or a custom function.

=item multilang_data_fields

return undef

This method can be overriden to give back different fields from the database columns in get_ext_data function (it controls multilang fields).

In a custom element make it return an array of strings.

WARNING: behaviour unpredictable if any string is not a database column of the multilang table or a custom function.


=back

=cut




1;
