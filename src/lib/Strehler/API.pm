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


1;
