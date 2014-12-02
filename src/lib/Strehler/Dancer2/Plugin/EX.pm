package Strehler::Dancer2::Plugin::EX;

use strict;
use warnings;

use Dancer2;
use Dancer2::Plugin;
use Strehler::Helpers;

register 'slug' => sub {
    my ( $dsl, $pattern, $template, $item_data, $extra_data ) = @_;

    my $slug_route = sub {
        my $slug = $dsl->params->{slug};

        my $item_type = $item_data->{'item-type'} || 'article';
        my $template = $template || 'slug';
        my $class = Strehler::Helpers::class_from_entity($item_type);
        my $language = $item_data->{'language'} || $dsl->params->{'language'} ||$dsl->config->{'Strehler'}->{'default_language'};
        my $category = $item_data->{'category'} || $dsl->params->{'category'} || undef;
        $extra_data ||= {};

        my $article = $class->get_by_slug($slug, $language);
        if( ! $article || ! $article->exists() || ($category && $article->get_category_name() ne $category))
        {
            $dsl->send_error("Not found", 404);
        }
        else
        {
            my %article_data = $article->get_ext_data($language);
            my $next = undef;
            my $prev = undef;
            my $next_data = undef;
            my $prev_data = undef;
            if($class->ordered())
            {
                $next = $article->next_in_category_by_order($language);
                $prev = $article->prev_in_category_by_order($language);
            }
            elsif($class->dated()) 
            {
                $next = $article->next_in_category_by_date($language);
                $prev = $article->prev_in_category_by_date($language);
            }
            else
            {
                $next = undef;
                $prev = undef;
            }
            if($prev && $prev->exists())                
            {
                my %prev_data_hash = $prev->get_ext_data($language);
                $prev_data = \%prev_data_hash;
            }
            if($next && $next->exists())
            {
                my %next_data_hash = $next->get_ext_data($language);
                $next_data = \%next_data_hash;
            }

            $dsl->template($template, { language => $language, element => \%article_data, prev => $prev_data, next => $next_data, %{$extra_data} });
        }
    };

    $dsl->any( ['get'] => $pattern, $slug_route);
};

register 'list' => sub {
    my ( $dsl, $pattern, $template, $item_data, $extra_data ) = @_;

    my $list_route = sub {
        my $page = $dsl->params->{'page'} || 1;
        my $order = $dsl->params->{'order'} || 'desc';
        my $template = $template || 'list';
        $extra_data ||= {};

        my $item_type = $item_data->{'item-type'} || 'article';
        my $class = Strehler::Helpers::class_from_entity($item_type);
        my $language = $item_data->{'language'} || $dsl->params->{language} || $dsl->config->{'Strehler'}->{'default_language'};
        my $category = $item_data->{'category'} || $dsl->params->{category} || undef;
        my $entries_per_page = $item_data->{'entries-per-page'} || $dsl->params->{'entries-per-page'} || 20;
        my $elements = $class->get_list({ page => $page, entries_per_page => $entries_per_page, category => $category, language => $language, ext => 1, published => 1, order => $order});
        $dsl->template( $template, {  elements => $elements->{'to_view'}, page => $page, order => $order, last_page => $elements->{'last_page'}, category => $category, item_type => $item_type, language => $language, %{$extra_data}}); 
    };

    $dsl->any( ['get'] => $pattern, $list_route);

};

sub latest_elements
{
    my $dsl = shift;
    my $request = shift;
    my $language = $dsl->params->{language} || $dsl->config->{'Strehler'}->{'default_language'};
    my %out;
    foreach my $k (keys %{$request})
    {
        my $local_language = $request->{$k}->{'language'} || $language;
        my $category = $request->{$k}->{'category'};
        my $item_type = $request->{$k}->{'item-type'} || 'article';
        my $by = $request->{$k}->{'by'} || 'date';

        my $class = Strehler::Helpers::class_from_entity($item_type);
        my $element;
        if($by eq 'date')
        {
           $element = $class->get_last_by_date($category, $language);
        }
        else
        {
           $element = $class->get_last_by_order($category, $language);
        }
        if($element)
        {
            my %element_data = $element->get_ext_data($language);
            $out{$k} = \%element_data;
        }
        else
        {
            $out{$k} = undef;
        }
    }
    return %out;
}

register 'latest' => sub {
        my $dsl = shift;
        my $request = shift;
        return latest_elements($dsl, $request);
};
register 'latest_page' => sub {
    my ($dsl, $pattern, $template, $request, $extra_data) = @_;
    $extra_data ||= {};
    my $latest_route = sub {
        $dsl->template( $template, {latest_elements($dsl, $request), %{$extra_data}}); 
    };
    $dsl->any( ['get'] => $pattern, $latest_route);
};


register_plugin;

1;

=encoding utf8

=head1 NAME

Strehler::Dancer2::Plugin::EX - Plugin for easy and fast site building!

=head1 DESCRIPTION

Using Strehler object to build a frontend may be a little messy because someone could need many instructions also to do simple things. EX plugin gives to the developer easy shortcuts, useful for standard scenarios, to write just elegant frontend code.

=head1 SYNOPSIS

Here is the route definition for Strehler Demo site, using EX plugin.

    get '/' => sub {template 'home';};

    slug '/ex/slug/:slug', 'element';
    list '/ex/list/dummy', 'dummy_list', { category => 'dummy' };
    latest_page '/ex/mypage', 'mypage', 
        { upper => { category => 'upper' }, 
          lower => { category => 'lower' }};

=head1 FUNCTIONS

All the functions available to generate routes are in the form:

keyword 'pattern/to/match', 'template', { options }

=head2 SLUG

Slug keyword allows you to retrieve data from a slugged entity and pass it to a template as I<element>.

Slug must be passed as a param named slug, in any way Dancer2 accept it.

Slug keyword passes to the template also the data about the previous and the next element in category (by order or publish date) as prev and next.

=head3 PARAMETERS

=over 4

=item item-type

The entity. It must be configured in Strehler configuration.

=item language

The language to use. If no language is configured plugin will try for a language entry in params. If also this solution will fail it will use the default language.

=item category

To restrict slugged entity retrieving just to a certain category.

=item extra_data

Hash reference. Any other variable you want for the template.

=back

=head2 LIST

List keyword gives you a list of entities' data in the template variable named elements. A route designed using list keyword accepts as params page and order to navigate the list. All the configuration parameter are passed to the template in template variables with the same name.

=head3 PARAMETERS

=over 4

=item item-type

The entity. It must be configured in Strehler configuration.

=item language

The language to use. If no language is configured plugin will try for a language entry in params. If also this solution will fail it will use the default language.

=item category

To restrict list retrieving just to a certain category.

=item entries-per-page

To change the length of a page.

=item extra_data

Hash reference. Any other variable you want for the template.


