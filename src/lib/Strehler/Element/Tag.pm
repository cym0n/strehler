package Strehler::Element::Tag;

use Moo;
use Dancer2;
use Dancer2::Plugin::DBIC;
use Data::Dumper;

has row => (
    is => 'ro',
);

sub BUILDARGS {
   my ( $class, @args ) = @_;
   my $tag = undef;
   if($#args == 0)
   {
        my $id = shift @args; 
        $tag = schema->resultset('Tag')->find($id);
   }
   elsif($#args == 1)
   {
       if($args[0] eq 'tag')
       {
            $tag = schema->resultset('Tag')->find({ tag => $args[1] });
       }
       if($args[0] eq 'row')
       {
            $tag = $args[1];
       }
   }
   return { row => $tag };
};

sub tags_to_string
{
    my $item = shift;
    my $item_type = shift;
    my @tags = schema->resultset('Tag')->search({ item_id => $item, item_type => $item_type });
    my $out = "";
    for(@tags)
    {
        $out .= $_->tag . ", ";
    }
    $out =~ s/, $//;
    return $out;
}

sub get_elements_by_tag
{
    my $tag = shift;
    my @images;
    my @articles;
    foreach(schema->resultset('Tag')->search({tag => $tag, item_type => 'image'}))
    {
        push @images, Strehler::Element::Image->new($_->item_id);
    }
    for(schema->resultset('Tag')->search({tag => $tag, item_type => 'article'}))
    {
        push @articles, Strehler::Element::Article->new($_->item_id);
    }
    return { images => \@images, articles => \@articles };
}

sub save_tags
{
    my $string = shift;
    my $item = shift;
    my $item_type = shift;
    $string =~ s/( +)?,( +)?/,/g;
    my @tags = split(',', $string);
    schema->resultset('Tag')->search({item_id => $item, item_type => $item_type})->delete_all();
    my %already;
    for(@tags)
    {
        if(! $already{$_})
        {
            $already{$_} = 1;
            my $new_tag = schema->resultset('Tag')->create({tag => $_, item_id => $item, item_type => $item_type});
        }
    }
}

sub get_configured_tags
{
    my $category = shift;
    my $mode = shift;
    $mode ||= 'string';
    my @types = ('article', 'image', 'both');
    my $out;
    foreach my $t (@types)
    {
        my @tags = schema->resultset('ConfiguredTag')->search({category_id => $category, item_type => $t});
        my $string = '';
        my $default = '';
        for(@tags)
        {
            $string .= $_->tag;
            $string .= ",";
            if($_->default_tag == 1)
            {
                $default = $_->tag;
            }
        }
        $string =~ s/,$//;
        if($string ne '')
        {
            if($mode eq 'string')
            {
                $out->{$t} = $string;
            }
            elsif($mode eq 'array')
            {
                my @list = split(',', $string);
                $out->{$t} = \@list;
            }
        }
        else
        {
            $out->{$t} = undef;
        }
        $out->{'default-' . $t} = $default;
    }
    return $out;
}

sub save_configured_tags
{
    my $string = shift;
    my $default_tag = shift;
    my $category = shift;
    my $type = shift;
    $default_tag ||= '';
    $string =~ s/( +)?,( +)?/,/g;
    $default_tag =~ s/^( +)//g;
    $default_tag =~ s/( +)$//g;
    my @tags = split(',', $string);
    my %already;
    for(@tags)
    {
        if(! $already{$_})
        {
            $already{$_} = 1;
            my $default = $_ eq $default_tag ? 1 : 0;
            if($type eq 'i')
            {
                schema->resultset('ConfiguredTag')->create({tag => $_, category_id => $category, item_type => 'image', default_tag => $default});
            }
            elsif($type eq 'a')
            {
                schema->resultset('ConfiguredTag')->create({tag => $_, category_id => $category, item_type => 'article', default_tag => $default});
            }
            elsif($type eq 'b')
            {
                schema->resultset('ConfiguredTag')->create({tag => $_, category_id => $category, item_type => 'both', default_tag => $default});
            }
        }
    }
}

sub clean_configured_tags
{
    my $category = shift;
    schema->resultset('ConfiguredTag')->search({ category_id => $category })->delete_all();
}



1;







