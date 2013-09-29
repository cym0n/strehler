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

sub save_tags
{
    my $string = shift;
    my $item = shift;
    my $item_type = shift;
    $string = s/ ?, ?/,/g;
    my @tags = split(',', $string);
    schema->resulset('Tag')->search({item_id => $item})->delete_all();
    for(@tags)
    {
        my $new_tag = schema->resultset('Tag')->create({tag => $_, item_id => $item, item_type => $item_type});
    }
}



1;







