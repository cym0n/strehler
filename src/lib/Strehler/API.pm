package Strehler::API;

use Dancer2 0.153002;
use Dancer2::Serializer::JSON;
use Strehler::Helpers;
use Strehler::Meta::Category;
use Data::Dumper;

prefix '/api/v1';

set layout => undef;

my $root_path = __FILE__;
$root_path =~ s/API\.pm//;

set views => $root_path . 'views';

get '/reference' => sub {
    my @entities = Strehler::Helpers::entities_list();
    my @single_calls;
    my @plural_calls;
    foreach my $e (@entities)
    {
        my $class = Strehler::Helpers::class_from_entity($e);
        next if ! $class->exposed();
        push @single_calls, '/api/v1/' . $e . '/&lt;id&gt;';
        push @single_calls, '/api/v1/' . $e . '/slug/&lt;slug&gt;';
        push @plural_calls, '/api/v1/' . $class->plural() . '/';
        push @plural_calls, '/api/v1/' . $class->plural() . '/&lt;category&gt;/&lt;subcategory&gt;/';
    }

    template "api/reference", { page_title => "API reference", single_calls => \@single_calls, plural_calls => \@plural_calls }, { layout => 'light-admin' };
};

get '/:entity/slug/:slug' => sub {
    my $entity = params->{entity};
    my $slug = params->{'slug'};
    my $callback = params->{'callback'} || undef;
    my $lang = params->{'lang'} || config->{'Strehler'}->{'default_language'};

    my $class = Strehler::Helpers::class_from_entity($entity);
    return pass if ! $class;
    return pass if ! $class->exposed();
    return pass if ! $class->slugged();
    my $obj = $class->get_by_slug($slug, $lang);
    if(! $obj)
    {
        return error_handler(404, "Element doesn't exists");
    }
    if($obj->publishable() && ! $obj->get_attr('published')) 
    {
        return error_handler(404, "Element doesn't exists");
    }
    my %data = $obj->get_ext_data($lang);    
    if($callback)
    {
        content_type('application/javascript');
    }
    else
    {
        content_type('application/json');
    }
    return serialize(\%data, $callback);
};

get '/:entity/:id' => sub {
    my $entity = params->{entity};
    my $id = params->{'id'};
    my $callback = params->{'callback'} || undef;
    my $lang = params->{'lang'} || config->{'Strehler'}->{'default_language'};

    my $class = Strehler::Helpers::class_from_entity($entity);
    return pass if ! $class;
    return pass if ! $class->exposed();
    my $obj = $class->new($id);
    if(! $obj->exists())
    {
        return error_handler(404, "Element doesn't exists");
    }
    if($obj->publishable() && ! $obj->get_attr('published')) 
    {
        return error_handler(404, "Element doesn't exists");
    }
    my %data = $obj->get_ext_data($lang);    
    if($callback)
    {
        content_type('application/javascript');
    }
    else
    {
        content_type('application/json');
    }
    return serialize(\%data, $callback);

};

get '/**/' => sub {
    my ($attributes) = splat;
    my ($entities, $category, $subcategory) = @{$attributes};
    my $callback = params->{'callback'} || undef;
    my $lang = params->{'lang'} || config->{'Strehler'}->{'default_language'};
    my $order = params->{'order'};
    my $order_by = params->{'order_by'};
    my $page = params->{'page'};
    my $entries_per_page = params->{'entries_per_page'} || 20;
    
    my $class = Strehler::Helpers::class_from_plural($entities);
    return pass if ! $class;
    return pass if ! $class->exposed();

    my $category_id = undef;
    my $ancestor = undef;
    if($category)
    {
        $subcategory ||= "";
        my $category_obj = Strehler::Meta::Category->explode_name("$category/$subcategory");
        if(! $category_obj->exists())
        {
            return error_handler(404, "Category doesn't exists");
        }
        if($subcategory)
        {
            $category_id = $category_obj->get_attr('id');
            $ancestor = undef;
        }
        else
        {
            $ancestor = $category_obj->get_attr('id');
            $category_id = undef;
        }
    }
    else
    {
        $category_id = undef;
        $ancestor = undef;
    }
    my $parameters = {
            order => $order,
            order_by => $order_by,
            language => $lang,
            entries_per_page => $entries_per_page,
            page => $page,
            ext => 1,
            published => 1,
            category_id => $category_id,
            ancestor => $ancestor
        };

    my $data = $class->get_list($parameters);    
    if($callback)
    {
        content_type('application/javascript');
    }
    else
    {
        content_type('application/json');
    }
    return serialize($data, $callback);
};

sub error_handler
{
    my $code = shift || 500;
    my $message = shift || "Generic error";
    my $callback = shift || undef;
    my $error_content = { error => $code, message => $message };
    my $serializer = Dancer2::Serializer::JSON->new();
    my $serialized = $serializer->serialize($error_content);
    if($callback)
    {
        content_type('application/javascript');
        $serialized = $callback . '( '. $serialized . ')';
    }
    else
    {
        content_type('application/json');
    }
    send_error($message, $code);
    return $serialized;
}

sub serialize
{
    my $content = shift;
    my $callback = shift;;
    my $serializer = Dancer2::Serializer::JSON->new();
    my $serialized = $serializer->serialize($content, {allow_blessed=>1,convert_blessed=>1});
    if($serializer->error)
    {
        return error_handler(500, "Serialization error: " . $serializer->error);
    }
    if($callback)
    {
        $serialized = $callback . '( '. $serialized . ')';
    }
    return $serialized;
}

=encoding utf8

=head1 NAME

Strehler::API - App that gives a RESTful interface to Strehler data

=head1 DESCRIPTION

Strehler::API is an out-of-the-box API system designed to give back contents created with Strehler backend in a JSON (or JSONp) shape.
It's main purpose is to make Strehler a complete server for client-side applications designed using advanced javascript, as L<Angular.js|https://angularjs.org/>.

Articles and Images are exposed through API by default, all the other custom entities can be exposed as well. Exposed flag was created for that purpose.

All the API calls are under B</api/v1/>

=head1 API REFERENCE

Strehler::API are read-only API so there're just two calls you can do, both GET, to obtain data.

=over 4

=item /api/v1/$entity/$entity_id

This API just return all the data related to entity $entity with id $entity_id. 
Data is always the extended data from get_ext_data in L<Strehler::Element>. You can pass to the call B<lang> as parameter to obtain data in a certain language. If no lang parameter is provided, data is returned using the default language.
If the entity is publishable, only data from published articles is returned. Calling for an unpublished article return 404. 

B<Example>: /api/v1/article/15

=item /api/v1/$entity/slug/$slug

As the previous API, using article slug instead of ID. It works only with slugged entities, entities that has L<Strehler::Element::Role:Slugged> as L<Strehler::Element::Article>.

=item /api/v1/$plural_entity/$category/$subcategory/

This API returns in a JSON format a call to get_list sub from L<Strehler::Element>. So data structure is:

    {
      page => 1,          #page retrieved
      last_page => 3,     #maximum callable page number
      to_view => $objects #list of objects, all returned with their extended data.
    } 

$plural_entity is the plural name of the entity. You can let Strehler derives it by itself from entity name using L<Lingua::EN::Inflect> or you can configure it in the config.yml or in the class as all other attributes.

$category and $subcategory are optional. If you call the API using them you'll retrieve all the elements under $category/$subcategory category. Pay attention that if you just call /api/v1/$plural_entity/$category/ system will return the objects under $category and all the objects under $category's subcategories.


API output is controlled by many parameters (a subset of get_list available parameters):

    lang: output language, as for single item API
    order, order_by: to change the way elements are ordered
    page: to control pagination
    entries_per_page: to say how many elements display every page

B<Example>: /api/v1/articles/foo/bar/

=item /api/v1/reference

Returns a web page where all the available APIs are listed. Automatically generated.

=back

=head2 JSONP CALLBACK

Adding B<callback> parameter to any API, return format will be JSONp instead of JSON.

=cut



1;
