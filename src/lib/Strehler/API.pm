package Strehler::API;

use Dancer2 0.11;
use Dancer2::Serializer::JSON;
use Strehler::Helpers;
use Strehler::Meta::Category;
use Data::Dumper;

prefix '/api/v1';

set layout => undef;

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
            entries_for_page => 20,
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

Strehker::API is an out-of-the-box API system designed on top of Strehler backend to give back contents created with Strehler backend in a JSON (or JSONp) shape.
It's main purpose is to make Strehler a complete server for client-side applications designed using advanced javascript, as Angular.js.

Articles and Images are exposed by API for default, all the others custom entities introduced can be exposed as well.

All the API calls are under B</api/v1/>

=head1 SYNOPSIS

    wget http://localhost:3000/api/v1/article/61

    --2014-06-29 11:48:52--  http://localhost:3000/api/v1/article/61
    Resolving localhost (localhost)... 127.0.0.1
    Connecting to localhost (localhost)|127.0.0.1|:3000... connected.
    HTTP request sent, awaiting response... 200 OK
    Length: 225 [application/json]
    Saving to: '61'

    100%[======================================>] 225         --.-K/s   in 0s      

    2014-06-29 11:48:54 (38.4 MB/s) - '61' saved [225/225]

    cat 61
    
    {"display_order":"1","category_name":"newcategory/newnew","image":"/upload/Poland-icon.png","published":null,"publish_date":null,"text":"domo domo domo","slug":"61-domo-domo","title":"domo domo","category":"newnew","id":"61"}

=head1 API reference

Strehler::API are read-only API so there're just two calls you can do, both in GET, to obtain data.

=over 4

=item /api/v1/$entity/$entity_id

This API just return all the data related to entity $entity with id $entity_id. 
Data is always the extended data from get_ext_data in L<Strehler::Element>. You can pass to the call B<lang> as parameter to obtain data in a certain language. If no lang parameter is provided, data is returned using the default language.
If the entity is publishable, only data from published articles is returned. 



=cut



1;
