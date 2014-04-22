package Strehler::Meta::Category;

use Moo;
use Dancer2;
use Dancer2::Plugin::DBIC;
use Strehler::Helpers;

has row => (
    is => 'ro',
);

sub BUILDARGS {
   my ( $class, @args ) = @_;
   my $category = undef;
   if($#args == 0)
   {
        my $id = shift @args; 
        $category = $class->get_schema()->resultset('Category')->find($id);
   }
   elsif($#args == 1)
   {
       if($args[0] eq 'row')
       {
            $category = $args[1];
       }
   }
   else
   {
        my %hash_args =  @args;
        if($hash_args{'parent'})
        {
            my $main = $class->get_schema()->resultset('Category')->find({ category => $hash_args{'parent'}, parent => undef });
            if($main)
            {
                $category = $main->categories->find({ category => $hash_args{'category'}});
            }
            else
            {
                $category = undef;
            }
        }
        else
        {
            $category = $class->get_schema()->resultset('Category')->find({ category => $hash_args{'category'}, parent => undef });
        }
   }
   return { row => $category };
};

sub get_schema
{
    if(config->{'Strehler'}->{'schema'})
    {
        return schema config->{'Strehler'}->{'schema'};
    }
    else
    {
        return schema;
    }
}

sub subcategories
{
    my $self = shift;
    my @subs;
    for($self->row->categories)
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
    $data{'name'} = $self->get_attr('category');
    $data{'ext_name'} = $self->ext_name;
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
    for my $e (Strehler::Helpers::get_categorized_entities())
    {
        my $class = Strehler::Helpers::get_entity_attr($e, 'class');
        eval "require $class";
        my $accessor = $class->category_accessor($category_row);
        return 1 if($category_row->$accessor->count() > 0);
    }
    return 0;
}
sub is_parent
{
   my $self = shift;
   return $self->row->categories->count() > 0;  
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
    $self->row->configured_tags->delete_all();
    $self->row->delete();
}

sub get_attr
{
    my $self = shift;
    my $attr = shift;
    return $self->row->get_column($attr);
}


sub make_select
{
    my $self = shift;
    my $parent = shift;
    my $option = shift;
    my @category_values = $self->get_schema()->resultset('Category')->search({ parent => $parent });
    my @category_values_for_select;
    my @base_select;
    push @base_select, { value => undef, label => "-- select --" }; 
    if($parent && $option  && $option eq 'ancestor')
    {
        push @category_values_for_select, { value => '*', label => "-- all --" }; 
    }
    my $category_count = 0;
    for(@category_values)
    {
        $category_count++;
        push @category_values_for_select, { value => $_->id, label => $_->category }
    }
    if($category_count > 0)
    {
        @category_values_for_select = (@base_select, @category_values_for_select);
        return \@category_values_for_select;
    }
    else
    {
        return \@base_select;
    }
}

sub get_list
{
    my $self = shift;
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
    my $rs = $self->get_schema()->resultset('Category')->search({parent => $args{'parent'}}, { order_by => { '-' . $args{'order'} => $args{'order_by'} }});
    for($rs->all())
    {
        my $cat = Strehler::Meta::Category->new($_->id);
        my %el = $cat->get_basic_data();
        push @to_view, \%el;
    }
    return  \@to_view;
}
sub explode_name
{
    my $self = shift;
    my $category_path = shift;
    my @cats = split '/', $category_path;
    if(exists $cats[1])
    {
        return Strehler::Meta::Category->new(parent => $cats[0], category => $cats[1]);
    }
    else
    {
        return Strehler::Meta::Category->new(category => $cats[0], parent => undef);
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
    if($row->parent)
    {
        $data->{'parent'} = $row->parent->id;
    }
    else
    {
        $data->{'parent'} = undef;
    }
    my $configured_tags = Strehler::Meta::Tag->get_configured_tags($self->ext_name(), \@entities);
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
    my $self = shift;
    my $id = shift;
    my $form = shift;
    my $ents = shift;
    my @entities = @{$ents};
    my $new_category;
    if($id)
    {
        $new_category = $self->get_schema()->resultset('Category')->find($id);
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
            $new_category = $self->get_schema()->resultset('Category')->create({category => $form->param_value('category'), parent => $form->param_value('parent')});
        }
        else
        {
            $new_category = $self->get_schema()->resultset('Category')->create({category => $form->param_value('category')});
        }
    }
    if($form->param_value('tags-all'))
    {
        Strehler::Meta::Tag->clean_configured_tags($new_category->id);
        Strehler::Meta::Tag->save_configured_tags($form->param_value('tags-all'), $form->param_value('default-all'), $new_category->id, 'all');
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
                    Strehler::Meta::Tag->clean_configured_tags($new_category->id);
                    $cleaned = 1;
                }
                Strehler::Meta::Tag->save_configured_tags($form->param_value('tags-' . $e), $form->param_value('default-' . $e), $new_category->id, $e);
            }
        }
    }
    return $new_category->id;
}

sub ext_name
{
    my $self = shift;
    my $category = $self->row->category;
    if($self->row->parent)
    {
        $category = $self->row->parent->category . '/' . $category;
    }
    return $category;
}


1;







