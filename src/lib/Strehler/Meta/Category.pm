package Strehler::Meta::Category;

use strict;
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

   # Create category using category table ID
   if($#args == 0)
   {
        my $id = shift @args; 
        $category = $class->get_schema()->resultset('Category')->find($id);
   }
   # Create category giving a row retrived using DBIx::Class
   elsif($#args == 1)
   {
       if($args[0] eq 'row')
       {
            $category = $args[1];
       }
   }
   else
   {
        # Create category using name as $parent/$category (used by explode_name)
        my %hash_args =  @args;
        if($hash_args{'parent'})
        {
            my $main = $class->get_schema()->resultset('Category')->find($hash_args{'parent'});
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
    my $deep = shift;
    my $already_collected = shift;
    my @subs;
    if($already_collected)
    {
        @subs = @{$already_collected};
    }

    return @subs if ! $self->row;
    for($self->row->categories)
    {
        my $category = Strehler::Meta::Category->new('row', $_);
        push @subs, $category;
        if($deep)
        {
            @subs = $category->subcategories(1, \@subs);
        }
        else
        {
            return @subs;
        }
    }
    return @subs;
}


sub get_basic_data
{
    my $self = shift;
    my %data;
    $data{'id'} = $self->get_attr('id');
    $data{'name'} = $self->get_attr('category');
    $data{'title'} = $self->get_attr('category');
    $data{'ext_name'} = $self->ext_name;
    $data{'parent'} = $self->get_attr('parent');
    return %data;
}

sub has_elements
{
    my $self = shift;
    my $category_row = $self->row;
    for my $e (Strehler::Helpers::get_categorized_entities())
    {
        my $cl = Strehler::Helpers::class_from_entity($e);
        my $accessor = $cl->category_accessor($category_row);
        return 1 if($category_row->$accessor->count() > 0);
    }
    return 0;
}
sub is_parent
{
   my $self = shift;
   return $self->row->categories->count() > 0;  
}
sub no_categories
{
    my $self = shift;
    my $how_many = $self->get_schema()->resultset('Category')->search({}); 
    return $how_many == 0;
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
    return -1 if($self->has_elements());
    return -2 if($self->is_parent());
    $self->row->configured_tags->delete_all();
    $self->row->delete();
    return 0;
}

sub get_attr
{
    my $self = shift;
    my $attr = shift;
    return undef if(! $self->exists);
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
        push @category_values_for_select, { value => 'anc:'.$parent, label => "-- all --" }; 
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
    $args{'depth'} ||= 0;
    my $search_criteria = undef;

    my @to_view;
    my $rs = $self->get_schema()->resultset('Category')->search({parent => $args{'parent'}}, { order_by => { '-' . $args{'order'} => $args{'order_by'} }});
    for($rs->all())
    {
        my $cat = Strehler::Meta::Category->new($_->id);
        my %el = $cat->get_basic_data();
        $el{'depth'} = $args{'depth'};
        if($args{'depth'} > 5)
        {
            $el{'display_name'} = $el{'ext_name'};
            $el{'display_name'} =~ s/^.*\/(.*\/.*)$/\.\.\.\/$1/;
        }
        else
        {
            $el{'display_name'} = $el{'name'};
        }
        push @to_view, \%el;
        my @subs = $self->get_list({ parent => $_->id, depth => $args{'depth'} + 1});
        push @to_view, @subs;
    }
    return  @to_view;
}
sub explode_name
{
    my $self = shift;
    my $category_path = shift;
    return Strehler::Meta::Category->new(-1) if(! $category_path);
    my $cat_id = $self->name_crawler($category_path, undef);
    if($cat_id)
    {
        return Strehler::Meta::Category->new($cat_id);
    }
    else
    {
        return Strehler::Meta::Category->new(-1);
    }
}
sub name_crawler
{
    my $self = shift;
    my $name = shift;
    my $parent = shift;

    my @subnames = split '/', $name;
    my $cat = shift @subnames;
    my $cat_obj = Strehler::Meta::Category->new(category => $cat, parent => $parent);
    $parent ||= '';
    if($cat_obj->exists())
    {
        if(@subnames)
        {
            return $self->name_crawler(join('/', @subnames), $cat_obj->get_attr('id'));
        }
        else
        {
            return $cat_obj->get_attr('id');
        }
    }
    else
    {
        return undef;
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
    return undef if(! $self->exists());
    my $category = $self->row->category;
    my $parent = $self->row->parent;
    while($parent)
    {
        $category = $parent->category . '/' . $category;
        $parent = $parent->parent;
    }
    return $category;
}

sub check_role
{
    my $self = shift;
    my $role = shift;
    if(! config->{Strehler}->{admin_secured})
    {
        return 1;
    }
    return ($role eq 'admin');
}

sub error_message
{
    my $self = shift;
    my $action = shift;
    my $code = shift;
    if($code == 0)
    {
        return "OK";
    }
    else
    {
        if($action eq 'delete')
        {
            if($code == -1)
            {
                return "Category " . $self->get_attr('category') . " is not empty! Deletion is impossible.";    
            }
            elsif($code == -2)
            {
                return "Category " . $self->get_attr('category') . " has subcategories! Deletion is impossible.";    
            }
        }
        return "An error has occurred";
    }
}


1;







