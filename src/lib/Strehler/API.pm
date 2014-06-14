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

    my $class = Strehler::Helpers::class_from_plural($entities);
    my $category_obj = Strehler::Meta::Category->explode_name("$category/$subcategory");
    return pass if ! $class;
    return pass if ! $class->exposed();
    if(! $category_obj->exists())
    {
        return error_handler(404, "Category doesn't exists");
    }
    my $data = $class->get_list({entries_for_page => 3});    
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
