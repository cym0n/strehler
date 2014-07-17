package Strehler::Helpers;

use Dancer2 0.11;
use Unicode::Normalize;
use Text::Unidecode;


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
sub entities_list
{
    my @standard_entities = ('article', 'image', 'user', 'log');
    my @configured_entities = keys %{config->{'Strehler'}->{'extra_menu'}};
    return (@standard_entities, @configured_entities);
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


