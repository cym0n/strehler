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
    my @entities = ('article', 'image'); #standard entities for Strehler
    my $extra = config->{'Strehler'}->{'extra_menu'};
    for(keys %{$extra})
    {
        if(config->{'Strehler'}->{'extra_menu'}->{$_}->{'categorized'})
        {
            push @entities, $_;
        }
    }
    return @entities;
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


