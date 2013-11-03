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



1;







