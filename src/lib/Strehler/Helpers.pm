package Strehler::Helpers;

use Dancer2 0.153002;
use Unicode::Normalize;
use Text::Unidecode;
use Data::Dumper;


#Barely copied from http://stackoverflow.com/questions/4009281/how-can-i-generate-url-slugs-in-perl
sub slugify
{
    my $input = shift;
    $input = NFKD($input);         # Normalize the Unicode string
    $input = unidecode($input);    # make accented letters not accented
    $input =~ tr/\000-\177//cd;    # Strip non-ASCII characters (>127)
    $input =~ s/[^\w\s-]//g;       # Remove all characters that are not word characters (includes _), spaces, or hyphens
    $input =~ s/^\s+|\s+$//g;      # Trim whitespace from both ends
    $input = lc($input);
    $input =~ s/[-\s]+/-/g;        # Replace all occurrences of spaces and hyphens with a single hyphen
    return $input;
} 

sub get_categorized_entities
{
    my @entities = entities_list();
    my @out;
    for(@entities)
    {
        my $cl = class_from_entity($_);
        push @out, $_ if $cl->categorized();
    }
    return @out;
}
sub standard_entities
{
    return ('article', 'image', 'user', 'log');
}
sub entities_list
{
    my @entities = standard_entities();
    my @configured_entities = keys %{config->{'Strehler'}->{'extra_menu'}};
    foreach my $e (@configured_entities)
    {
        push @entities, $e if(! grep {$_ eq $e} @entities);
    }
    return @entities;
}
sub top_bars
{
    my @entities = entities_list();
    my @editor_menu;
    my @admin_menu;
    foreach my $e (@entities)
    {
        my $c = class_from_entity($e);
        if($c->visible())
        {
            if($c->allowed_role() && $c->allowed_role() eq "admin")
            {
                push @admin_menu, { name => $e, label => $c->label() };
            }
            else
            {
                push @editor_menu, { name => $e, label => $c->label() };
            }
        }
    }
    return \@editor_menu, \@admin_menu;
}


sub class_from_entity
{
    my $entity = shift;
    my $class;
    if($entity eq 'article')
    {
        $class = "Strehler::Element::Article";
    }
    elsif($entity eq 'image')
    {
        $class = "Strehler::Element::Image";
    }
    elsif($entity eq 'user')
    {
        $class = "Strehler::Element::User";
    }
    elsif($entity eq 'log')
    {
        $class = "Strehler::Element::Log";
    }
    else
    {
        $class = config->{'Strehler'}->{'extra_menu'}->{$entity}->{class};
    }
    if($class)
    {
        eval("require $class");
        return $class;
    }
}

sub class_from_plural
{
    my $plural = shift;
    foreach my $class ('Strehler::Element::Article', 'Strehler::Element::Image', 'Strehler::Element::User', 'Strehler::Element::Log')
    {
        eval("require $class");
        if($class->plural() eq $plural)
        {
            return $class;
        }
    }
    foreach my $entity (keys %{config->{'Strehler'}->{'extra_menu'}})
    {
        my $entity_class = config->{'Strehler'}->{'extra_menu'}->{$entity}->{'class'};
        eval("require $entity_class");
        if($entity_class->plural() eq $plural)
        {
            return $entity_class;
        }
    }
    return undef;
}

=encoding utf8

=head1 NAME

Strehler::Helpers - Helpers

=head1 DESCRIPTION

Just few methods used in Strehler that could come useful throughtout in the application and also while developing on top of Strehler.

=head1 FUNCTIONS

=over 4

=item slugify 

arguments: $string

return value: $slugified

This method take a string and return the slugified version of it. Used to retrieve articles.

=item class_from_entity

arguments: entity

return value $class

Return the $class related to the given entity

=back

=cut

1;


