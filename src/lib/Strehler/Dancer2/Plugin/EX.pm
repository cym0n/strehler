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
        if( ! $article->exists() || ($category && $article->get_category_name() ne $category))
        {
            return undef;
        }
        else
        {
            my %article_data = $article->get_ext_data($language);
            my $next_slug = undef;
            my $prev_slug = undef;
            my $next = $article->next_in_category_by_order($language);
            if($next->exists())
            {
                $next_slug = $next->get_attr_multilang('slug', $language);
            }
            my $prev = $article->prev_in_category_by_order($language);
            if($prev->exists())
            {
                $prev_slug = $prev->get_attr_multilang('slug', $language);
            }
            $dsl->template($template, { element => \%article_data, prev_slug => $prev_slug, next_slug => $next_slug, %{$extra_data} });
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

register_plugin;

1;


