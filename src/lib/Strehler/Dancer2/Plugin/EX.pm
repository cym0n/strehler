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

        my $item_type = $dsl->config->{'Strehler'}->{'default_entity'} || 'article';
        my $language  = $dsl->params->{'language'} ||$dsl->config->{'Strehler'}->{'default_language'};
        my $category = undef;

        if($item_data && ref($item_data))
        {
            $item_type = $item_data->{'item-type'} || $item_type;
            $language  = $item_data->{'language'}  || $language;
            $category  = $item_data->{'category'}  || undef;
        }
        else
        {
            $category  = $item_data;
        }
            
        my $template = $template || 'slug';
        my $class = Strehler::Helpers::class_from_entity($item_type);
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
        my $template = $template || 'list';
        $extra_data ||= {};

        my $item_type =  $dsl->config->{'Strehler'}->{'default_entity'} ||  'article';
        my $language = $dsl->params->{language} || $dsl->config->{'Strehler'}->{'default_language'};
        my $entries_per_page = $dsl->params->{'entries-per-page'} || undef;
        my $category = undef;
        my $order_by = $dsl->params->{'order-by'} || undef;
        my $order = $dsl->params->{'order'} || undef;

        if($item_data && ref($item_data))
        {
            $item_type = $item_data->{'item-type'} || $item_type;
            $language = $item_data->{'language'} || $language;
            $entries_per_page = $item_data->{'entries-per-page'} || $entries_per_page;
            $category = $item_data->{'category'} || undef;
            $order_by = $item_data->{'order-by'} || $order_by;
            $order = $item_data->{'order'} || undef;
        }
        else
        {
            $category = $item_data;
        }
        my $class = Strehler::Helpers::class_from_entity($item_type);
         
        my %parameters = ( page => $page, 
                           entries_per_page => $entries_per_page, 
                           category => $category, 
                           language => $language, 
                           order => $order, 
                           order_by => $order_by );
        my %get_list_parameters = ( %parameters, ( ext => 1, published => 1 ));               
        my $elements = $class->get_list(\%get_list_parameters);
        my %template_parameters = ( %parameters, ( item_type => $item_type, elements => $elements->{'to_view'}, last_page => $elements->{'last_page'}), %{$extra_data}); 
        $dsl->template( $template, \%template_parameters); 
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
        my $local_language = $language;
        my $category = undef;
        my $item_type = $dsl->config->{'Strehler'}->{'default_entity'} || 'article';
        my $by = 'date';

        if(ref($request->{$k}))
        {
            $local_language = $request->{$k}->{'language'} || $language;
            $category = $request->{$k}->{'category'} || undef;
            $item_type = $request->{$k}->{'item-type'} || $item_type;
            $by = $request->{$k}->{'by'} || $by;
        }
        else
        {
            $category = $request->{$k};
        }

        my $class = Strehler::Helpers::class_from_entity($item_type);
        my $element = undef;
        if($by eq 'date')
        {
           $element = $class->get_last_by_date($category, $language);
        }
        elsif($by eq 'order')
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
    list '/ex/list/dummy', 'dummy_list', 'dummy';
    latest_page '/ex/mypage', 'mypage', 
        { upper => 'upper', 
          lower => 'lower' };

=head1 FUNCTIONS

All the functions available to generate routes are in the form:

keyword 'pattern/to/match', 'template', { options }, { extra_data }

When you have to configure just the category where contenst are, you can pass it just as its name instead of options hash. All the others values will be the default ones. If you want to use as default an item_type different from article default_entity Strehler parameter will come useful to you.

extra_data is just an hash reference to any variable you want in the template.

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

=item order-by

To decide what database field to use to order elements. 

Pay attention: an ordered entity will use display_order by default, a dated (but not ordered) entity publish_date. Otherwise, id will be used.

=item order

'asc' or 'desc' 

=item extra_data

Hash reference. Any other variable you want for the template.

=back

=head2 LATEST_PAGE

Consider a scenario where you need to update a content once in a while and you don't really need to keep an archive for it. You could always updating the same content, but why don't exploit Strehler power to have a little of version control?

Latest_page retrieve data from latest content (by publish_date or by orded) in a category and can be used to manage multiple contents. This way you can build a customized page with all the area freely editable.

=head3 PARAMETERS

Latest_page parameters are organized as a hash of hashes where every key of the primary hash is the name of the template variable where content data will be stored. Each key points to an hash of parameters for retrieving the content.

For each elements parameters are quite the same of the previous keywords.

=over 4

=item item-type

The entity. It must be configured in Strehler configuration.

=item language

The language to use. If no language is configured plugin will try for a language entry in params. If also this solution will fail it will use the default language.

=item category

To restrict list retrieving just to a certain category.

=item by

It can assume values "date" or "order", it's the criteria to calculate latest article.

=back

=head2 LATEST

As latest_page, but returns an hash and not a route, so you can use it when calling the template in a more complex situation.

    template 'the_page', { parameter => 'yadda', 
                           parameter2 => 'badda', 
                           latest { a_page => { category => 'cat1' }, 
                                    another => { category => 'cat2' }}
                         };

=cut
