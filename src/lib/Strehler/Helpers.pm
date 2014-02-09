package Strehler::Helpers;

use Dancer2;
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

sub get_entity_data
{
    my $entity = shift;
    my %data;
    if($entity eq 'article')
    {
        %data = ( 'auto' => 1,
                  'label' => 'Articles',
                  'class' => 'Strehler::Element::Article',
                  'creatable' => 1,
                  'updatable' => 1,
                  'deletable' => 1,
                  'categorized' => 1,
                  'publishable' => 1,
                  'ordered' => 1,
                  'dated' => 1,
                  'custom_list_view' => undef,
                  'form' => undef,
                  'multilang_form' => undef,
                  'role' => undef );
    }
    elsif($entity eq 'image')
    {
        %data = ( 'auto' => 1,
                  'label' => 'Images',
                  'class' => 'Strehler::Element::Image',
                  'creatable' => 1,
                  'updatable' => 1,
                  'deletable' => 1,
                  'categorized' => 1,
                  'ordered' => 0,
                  'dated' => 0,
                  'publishable' => 0,
                  'custom_list_view' => 'admin/image_list',
                  'form' => undef,
                  'multilang_form' => undef,
                  'role' => undef );
    }
    elsif($entity eq 'user')
    {
        %data = ( 'auto' => 1,
                  'label' => 'Users',
                  'class' => 'Strehler::Element::User',
                  'creatable' => 1,
                  'updatable' => 1,
                  'deletable' => 1,
                  'categorized' => 0,
                  'ordered' => 0,
                  'dated' => 0,
                  'publishable' => 0,
                  'custom_list_view' => undef,
                  'form' => undef,
                  'multilang_form' => undef,
                  'role' => 'admin' );
    }
    elsif($entity eq 'category')
    {
        %data = ( 'auto' => 0,
                  'role' => 'admin' );
    }
    elsif($entity eq 'log')
    {
        %data = ( 'auto' => 1,
                  'label' => 'Logs',
                  'class' => 'Strehler::Element::Log',
                  'creatable' => 0,
                  'updatable' => 0,
                  'deletable' => 0,
                  'categorized' => 0,
                  'ordered' => 0,
                  'dated' => 0,
                  'publishable' => 0,
                  'custom_list_view' => 'admin/log_list',
                  'form' => undef,
                  'multilang_form' => undef,
                  'role' => 'admin' );
    }
    elsif(config->{'Strehler'}->{'extra_menu'}->{$entity})
    {
        %data = ( 'auto' => config->{'Strehler'}->{'extra_menu'}->{$entity}->{auto},
                  'label' => config->{'Strehler'}->{'extra_menu'}->{$entity}->{label},
                  'class' => config->{'Strehler'}->{'extra_menu'}->{$entity}->{class},
                  'creatable' => config->{'Strehler'}->{'extra_menu'}->{$entity}->{creatable} || 1,
                  'updatable' => config->{'Strehler'}->{'extra_menu'}->{$entity}->{updatable} || 1,
                  'deletable' => config->{'Strehler'}->{'extra_menu'}->{$entity}->{deletable} || 1,
                  'categorized' => config->{'Strehler'}->{'extra_menu'}->{$entity}->{categorized} || 0,
                  'ordered' => config->{'Strehler'}->{'extra_menu'}->{$entity}->{ordered} || 0,
                  'dated' => config->{'Strehler'}->{'extra_menu'}->{$entity}->{dated} || 0,
                  'publishable' => config->{'Strehler'}->{'extra_menu'}->{$entity}->{publishable} || 0,
                  'custom_list_view' => config->{'Strehler'}->{'extra_menu'}->{$entity}->{custom_list_view},
                  'form' => config->{'Strehler'}->{'extra_menu'}->{$entity}->{form},
                  'multilang_form' => config->{'Strehler'}->{'extra_menu'}->{$entity}->{multilang_form},
                  'role' => config->{'Strehler'}->{'extra_menu'}->{$entity}->{role} );
    }
    else
    {
        return undef;
    }
    return %data;
}
sub get_entity_attr
{
    my $entity = shift;
    my $attr = shift;
    my %entity_data = get_entity_data($entity);
    if(%entity_data)
    {
        return $entity_data{$attr};
    }
    else
    {
        return undef;
    }
}

1;


