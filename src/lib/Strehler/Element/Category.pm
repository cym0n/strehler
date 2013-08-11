package Strehler::Element::Category;

use Moo;
use Dancer2 ":syntax";
use Dancer2::Plugin::DBIC;
use Data::Dumper;

has row => (
    is => 'ro',
);

sub BUILDARGS {
   my ( $class, @args ) = @_;
   my $category = undef;
   if($#args == 0)
   {
        my $id = shift @args; 
        $category = schema->resultset('Category')->find($id);
   }
   else
   {
       if($args[0] eq 'name')
       {
            $category = schema->resultset('Category')->find({ category => $args[1] });
       }
   }
   return { row => $category };
};

sub get_basic_data
{
    my $self = shift;
    my %data;
    $data{'id'} = $self->get_attr('id');
    $data{'title'} = $self->get_attr('category'); #For compatibility with the views shared with images and articles
    $data{'name'} = $self->get_attr('category');
    return %data;
}

sub has_elements
{
    my $self = shift;
    my $category_row = $self->row;
    return $category_row->images->count() > 0 || $category_row->articles->count() > 0
}
sub max_article_order
{
    my $self = shift;
    my $max = $self->row->articles->search()->get_column('display_order')->max();
    return $max;
}

sub delete
{
    my $self = shift;
    $self->row->delete();
    $self->row->images->update( { category => undef } );
    $self->row->articles->update( { category => undef } );

}

sub get_attr
{
    my $self = shift;
    my $attr = shift;
    return $self->row->get_column($attr);
}

#Static helpers

sub make_select
{
    my @category_values = schema->resultset('Category')->all();
    my @category_values_for_select;
    push @category_values_for_select, { value => undef, label => "-- seleziona --" }; 
    for(@category_values)
    {
        push @category_values_for_select, { value => $_->id, label => $_->category }
    }
    return \@category_values_for_select;
}

sub get_list
{
    my $params = shift;
    my %args;
    if($params)
    {
        %args = %{ $params };
    }
    else
    {
        %args = ();
    }
    $args{'order'} ||= 'desc';
    $args{'order_by'} ||= 'id';
    my $search_criteria = undef;

    my @to_view;
    my $rs = schema->resultset('Category')->search(undef, { order_by => { '-' . $args{'order'} => $args{'order_by'} }});
    for($rs->all())
    {
        my $cat = Strehler::Element::Category->new($_->id);
        my %el = $cat->get_basic_data();
        push @to_view, \%el;
    }
    return  \@to_view;
}


sub save_form
{
    my $form = shift;
    my $new_category = schema->resultset('Category')->create({category => $form->param_value('category') });
    return Strehler::Element::Category->new($new_category->id());     
}


1;







