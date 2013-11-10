package Strehler::Element::Category;

use Moo;
use Dancer2;
use Dancer2::Plugin::DBIC;
use Strehler::Element::Tag;
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
   elsif($#args == 1)
   {
       if($args[0] eq 'name')
       {
            $category = schema->resultset('Category')->find({ category => $args[1] });
       }
       if($args[0] eq 'row')
       {
            $category = $args[1];
       }
   }
   else
   {
        my %hash_args =  @args;
        my $main = schema->resultset('Category')->find({ category => $hash_args{'parent'}, parent => undef });
        if($main)
        {
            $category = $main->subcategories->find({ category => $hash_args{'category'}});
        }
        else
        {
            $category = undef;
        }
   }
   return { row => $category };
};

sub subcategories
{
    my $self = shift;
    my @subs;
    for($self->row->subcategories)
    {
        push @subs, Strehler::Element::Category->new('row', $_);
    }
    return @subs;
}


sub get_basic_data
{
    my $self = shift;
    my %data;
    $data{'id'} = $self->get_attr('id');
    $data{'title'} = $self->get_attr('category'); #For compatibility with the views shared with images and articles
    $data{'name'} = $self->get_attr('category');
    if(! $self->get_attr('parent'))
    {
        my @subs = $self->subcategories();
        if($#subs != -1)
        {
            $data{'subcategories'} = [];
            for(@subs)
            {
                my %subdata = $_->get_basic_data();
                push @{$data{'subcategories'}}, \%subdata;
            }
        }
    }
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
    my $parent = shift;
    my @category_values = schema->resultset('Category')->search({ parent => $parent });
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
    $args{'parent'} ||= undef;
    my $search_criteria = undef;

    my @to_view;
    my $rs = schema->resultset('Category')->search({parent => $args{'parent'}}, { order_by => { '-' . $args{'order'} => $args{'order_by'} }});
    for($rs->all())
    {
        my $cat = Strehler::Element::Category->new($_->id);
        my %el = $cat->get_basic_data();
        push @to_view, \%el;
    }
    return  \@to_view;
}
sub explode_tree
{
    my $cat_param = shift;    
    my $cat = undef;
    my $subcat = undef;
    if($cat_param)
    {
        my $category = Strehler::Element::Category->new($cat_param);
        my $parent = $category->get_attr('parent'); 
        if($parent)
        {
            $subcat = $cat_param;
            $cat = $parent;
        }
        else
        {
            $cat = $cat_param;
        }
        return ($cat, $subcat);
    }
    else
    {
        return (undef, undef);
    }
}
sub explode_name
{
    my $category_path = shift;
    my @cats = split '/', $category_path;
    if(exists $cats[1])
    {
        return Strehler::Element::Category->new(parent => $cats[0], category => $cats[1]);
    }
    else
    {
        return Strehler::Element::Category->new(name => $cats[0]);
    }
}
  



sub exists
{
    my $self = shift;
    if($self->row)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

sub get_form_data
{
    my $self = shift;
    my $row = $self->row;
    my $data;
    $data->{'category'} = $row->category;
    $data->{'parent'} = $row->parent;
    my $configured_tags = Strehler::Element::Tag::get_configured_tags($row->id, 'string');
    if($configured_tags->{'both'})
    {
        $data->{'type-1'} = 'b';
        $data->{'tags-1'} = $configured_tags->{'both'};
        $data->{'default-1'} = $configured_tags->{'default-both'};
    }
    else
    {
        my $counter = 1;
        if($configured_tags->{'article'})
        {   
            $data->{'type-1'} = 'a';
            $data->{'tags-1'} = $configured_tags->{'article'};
            $data->{'default-1'} = $configured_tags->{'default-article'};
            $counter++;
        }
        if($configured_tags->{'image'})
        {   
            $data->{'type-'.$counter} = 'i';
            $data->{'tags-'.$counter} = $configured_tags->{'image'};
            $data->{'default-'.$counter} = $configured_tags->{'default-image'};
            $counter++;
        }
    }
    return $data;
}

sub save_form
{
    my $id = shift;
    my $form = shift;
    my $new_category;
    if($id)
    {
        $new_category = schema->resultset('Category')->find($id);
        if($form->param_value('parent'))
        {
            $new_category->update({category => $form->param_value('category'), parent => $form->param_value('parent')});
        }
        else
        {
            $new_category->update({category => $form->param_value('category')});
        }
    }
    else
    {
        if($form->param_value('parent'))
        {
            $new_category = schema->resultset('Category')->create({category => $form->param_value('category'), parent => $form->param_value('parent')});
        }
        else
        {
            $new_category = schema->resultset('Category')->create({category => $form->param_value('category')});
        }
    }
    if($form->param_value('tags-1') || $form->param_value('tags-2'))
    {
        Strehler::Element::Tag::clean_configured_tags($new_category->id);
        my $first_form = $form->param_value('type-1');
        if($form->param_value('tags-1'))
        {

            Strehler::Element::Tag::save_configured_tags($form->param_value('tags-1'), $form->param_value('default-1'), $new_category->id, $form->param_value('type-1'));
        }
        if($form->param_value('tags-1'))
        {
            if($first_form ne 'b' && $first_form ne  $form->param_value('type-2'))
            {
                Strehler::Element::Tag::save_configured_tags($form->param_value('tags-2'), $form->param_value('default-2'), $new_category->id, $form->param_value('type-2'));
            }
        }

    }
}


1;







