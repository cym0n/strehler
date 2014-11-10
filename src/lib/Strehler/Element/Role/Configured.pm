package Strehler::Element::Role::Configured;

use Moo::Role;
use Dancer2;
use Dancer2::Plugin::DBIC;
use Lingua::EN::Inflect qw(PL classical);

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
sub plural
{
    my $self = shift;
    classical(1);
    my $plural = PL($self->item_type());
    $plural = $plural . 's' if $plural eq $self->item_type();
    return $plural;
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
sub _property
{
    my $self = shift;
    my $prop = shift;
    my $default = shift;
    return exists config->{'Strehler'}->{'extra_menu'}->{$self->item_type()}->{$prop} ? config->{'Strehler'}->{'extra_menu'}->{$self->item_type()}->{$prop} : $default;
}
sub visible
{
    my $self = shift;
    return $self->_property('visible', 1);
}
sub auto
{
    my $self = shift;
    return $self->_property('auto', 1);
}
sub exposed
{
    my $self = shift;
    return $self->_property('exposed', 1);
}
sub slugged
{
    my $self = shift;
    return $self->can('get_by_slug');
}
sub label
{
    my $self = shift;
    return $self->_property('label', '???');
}
sub class
{
    my $self = shift;
    return $self->_property('class', 'Strehler::Element');
}
sub creatable
{
    my $self = shift;
    return $self->_property('creatable', 1);
}
sub updatable
{
    my $self = shift;
    return $self->_property('updatable', 1);
}
sub deletable
{
    my $self = shift;
    return $self->_property('deletable', 1);
}
sub categorized
{
    my $self = shift;
    return $self->_property('categorized', 0);
}
sub ordered
{
    my $self = shift;
    return $self->_property('ordered', 0);
}
sub dated
{
    my $self = shift;
    return $self->_property('dated', 0);
}
sub publishable
{
    my $self = shift;
    return $self->_property('publishable', 0);
}
sub form
{
    my $self = shift;
    return $self->_property('form', undef);
}
sub multilang_form
{
    my $self = shift;
    return $self->_property('multilang_form', undef);
}
sub allowed_role
{
    my $self = shift;
    if(exists config->{'Strehler'}->{'extra_menu'}->{$self->item_type()}->{allowed_role})
    {
        return config->{'Strehler'}->{'extra_menu'}->{$self->item_type()}->{allowed_role};
    }
    elsif(exists config->{'Strehler'}->{'extra_menu'}->{$self->item_type()}->{role}) 
    {
        #For retrocompatibility
        return config->{'Strehler'}->{'extra_menu'}->{$self->item_type()}->{role};
    }
    else
    {
        return undef;
    }
}
sub custom_list_template
{
    my $self = shift;
    return $self->_property('custom_list_template', undef);
}

sub entity_data
{
    my $self = shift;
    my @attributes = ('auto', 
                      'exposed',
                      'slugged',
                      'label', 
                      'class', 
                      'creatable', 
                      'updatable', 
                      'deletable',
                      'categorized',
                      'ordered',  
                      'dated',
                      'publishable',
                      'form',
                      'multilang_form',
                      'allowed_role',
                      'custom_list_template',
                      'visible');
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
sub custom_add_snippet
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

Slugged attribute is special, it's based on introspection on the class. You can't change it in config.yml and overriding it could be a bad idea.

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

=item _property

return $prop

Generic function to manage flag properties.

=item "flag functions"

=over 6

=item *

auto

=item *

exposed

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

form

=item *

multilang_form

=item *

allowed_role

=item * 

custom_list_template

=back

All these functions read from configuration file the property. They can be overriden to configure different values for properties without involving configuration file.

For the meaning of every flag see L<Strehler::Manual::ExtraEntityConfiguration>

=item "complex info functions"

=over 6

=item * 

data_fields

=item *

multilang_data_fields

=item *

custom_add_snippet

=back

All these functions have no reference in the configuration file, but overriding them you can obtain more customization.

For the meaning of each function  see L<Strehler::Manual::ExtraEntityConfiguration>

=item get_schema

return $schema

Wrapper for Dancer2 schema keyword, used internally to allow developer to use a different schema from default for Strehler

=item entity_data

return %data

Return all the configuration for an element as an hash


=back

=cut




1;
