package Strehler::API;

use Dancer2 0.11;
use Dancer2::Serializer::JSON;
use Strehler::Helpers;
use Data::Dumper;

prefix '/api/v1';

set layout => undef;

get '/:entity/:id' => sub {

    my $entity = params->{entity};
    my $id = params->{'id'};
    my $callback = params->{'callback'};
    my $lang = params->{'lang'} || config->{'Strehler'}->{'default_language'};
    if($callback)
    {
        content_type('application/javascript');
    }
    else
    {
        content_type('application/json');
    }
    my $class = Strehler::Helpers::class_from_entity($entity);
    pass if ! $class;
    my %data = $class->new($id)->get_ext_data($lang);    
    my $serializer = Dancer2::Serializer::JSON->new();
    my $serialized = $serializer->serialize(\%data);
    if($callback)
    {
        $serialized = $callback . '( '. $serialized . ')';
    }
    return $serialized;

};

get '/:entities' => sub {
    content_type('application/json');
    my $entities = params->{entities};
    my $class = Strehler::Helpers::class_from_plural($entities);
    pass if ! $class;
    my $data = $class->get_list({entries_for_page => 3});    
    my $serializer = Dancer2::Serializer::JSON->new();
    my $serialized = $serializer->serialize($data->{to_view}, {allow_blessed=>1,convert_blessed=>1});
    return $serialized;
};




1;
