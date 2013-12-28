package Strehler::Meta::Category;

use Moo;
use Dancer2;
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
        push @subs, Strehler::Meta::Category->new('row', $_);
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
        my $cat = Strehler::Meta::Category->new($_->id);
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
        my $category = Strehler::Meta::Category->new($cat_param);
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
        return Strehler::Meta::Category->new(parent => $cats[0], category => $cats[1]);
    }
    else
    {
        return Strehler::Meta::Category->new(name => $cats[0]);
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
    my $ents = shift;
    my @entities = @{$ents};
    push @entities, 'all';
    my $row = $self->row;
    my $data;
    $data->{'category'} = $row->category;
    $data->{'parent'} = $row->parent;
    my $configured_tags = Strehler::Meta::Tag::get_configured_tags($row->id, \@entities);
    for(@entities)
    {
       my $e = $_;
       if($configured_tags->{$e})
       {
            $data->{'tags-' . $e} = $configured_tags->{$e};
            $data->{'default-' . $e} = $configured_tags->{'default-' . $e};
       } 
    }
    return $data;
}

sub save_form
{
    my $id = shift;
    my $form = shift;
    my $ents = shift;
    my @entities = @{$ents};
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
    if($form->param_value('tags-all'))
    {
        Strehler::Meta::Tag::clean_configured_tags($new_category->id);
        Strehler::Meta::Tag::save_configured_tags($form->param_value('tags-all'), $form->param_value('default-all'), $new_category->id, 'all');
    }
    else
    {
        my $cleaned = 0;
        for(@entities)
        {
            my $e = $_;
            if($form->param_value('tags-' . $e))
            {
                if(! $cleaned)
                {
                    Strehler::Meta::Tag::clean_configured_tags($new_category->id);
                    $cleaned = 1;
                }
                Strehler::Meta::Tag::save_configured_tags($form->param_value('tags-' . $e), $form->param_value('default-' . $e), $new_category->id, $e);
            }
        }
    }
}


1;







