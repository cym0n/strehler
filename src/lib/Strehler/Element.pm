package Strehler::Element;

use Moo;
use Dancer2;
use Dancer2::Plugin::DBIC;
use Strehler::Meta::Tag;
use Strehler::Meta::Category;

has row => (
    is => 'ro',
);

sub BUILDARGS {
   my ( $class, @args ) = @_;
   my $id = shift @args; 
   my $article;
   if(! $id)
   {
        $article = undef;
   }
   else
   {
        $article = schema->resultset($class->ORMObj())->find($id);
   }
   return { row => $article };
};

sub category_accessor
{
    my $self = shift;
    my $category = shift;
    return $category->can($self->metaclass_data('category_accessor'));
}

sub item_type
{
    my $self = shift;
    return $self->metaclass_data('item_type');
}

sub ORMObj
{
    my $self = shift;
    return $self->metaclass_data('ORMObj');
}
sub multilang_children
{
    my $self = shift;
    return $self->metaclass_data('multilang_children');
}
sub publishable
{
    my $self = shift;
    my $item = $self->metaclass_data('item_type');
    return 1 if($item eq 'article');
    if(config->{'Strehler'}->{'extra_menu'}->{$item}->{'publishable'})
    {
        return config->{'Strehler'}->{'extra_menu'}->{$item}->{'publishable'};
    }
    else
    {
        return 0;
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
sub delete
{
    my $self = shift;
    my $children = $self->row->can($self->multilang_children());
    $self->row->$children->delete_all() if($children);
    $self->row->delete();
}

sub get_attr
{
    my $self = shift;
    my $attr = shift;
    return $self->row->get_column($attr);
}
sub get_attr_multilang
{
    my $self = shift;
    my $attr = shift;
    my $lang = shift;
    my $children = $self->row->can($self->multilang_children());
    return undef if not $children;
    my $content = $self->row->$children->find({'language' => $lang});
    if($content)
    {
        return $content->get_column($attr);
    }
    else
    {
        return undef;
    }
}
sub has_language
{
    my $self = shift;
    my $language = shift;
    my $children = $self->row->can($self->multilang_children());
    return 1 if not $children;
    my $content = $self->row->$children->find({language => $language});
    if($content)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}
sub get_tags
{
    my $self = shift;
    my $tags = Strehler::Meta::Tag->tags_to_string($self->get_attr('id'), $self->item_type());
    return $tags;
}
sub get_category_name
{
    my $self = shift;
    if($self->row->can('category'))
    {
            my $category = Strehler::Meta::Category->new($self->row->category->id);
            return $category->ext_name();
    }
    else
    {
        return undef;
    }
}
sub max_category_order
{
    my $self = shift;
    my $category_id = shift;
    my $max;
    if($category_id)
    {
        my $category = Strehler::Meta::Category->new($category_id);
        my $category_accessor = $self->category_accessor($category->row);
        $max = $category->row->$category_accessor->search()->get_column('display_order')->max();
    }
    else
    {
        $max = schema->resultset($self->ORMObj())->search()->get_column('display_order')->max();
    }
    return $max || 0;
}




sub get_basic_data
{
    my $self = shift;
    my %data = $self->row->get_columns;
    $data{'id'} = $self->get_attr('id');
    $data{'title'} = $self->main_title;
    if($self->row->can('category'))
    {
        $data{'category'} = $self->row->category->category;
    }
    if($self->row->result_source->has_column('published'))
    {
        $data{'published'} = $self->get_attr('published');
    }
    foreach my $attribute (keys %data)
    {
        my $accessor = $self->can($attribute);
        if($accessor)
        {
            $data{$attribute} = $self->$accessor();
        }
    }
    $data{'category_name'} = $self->get_category_name();
    return %data;
}
sub get_ext_data
{
    my $self = shift;
    my $language = shift;
    my %data;
    %data = $self->get_basic_data();
    my $children = $self->row->can($self->multilang_children());
    if($children)
    {
        my $multilang_row = $self->row->$children->find({ language => $language });
        my %multilang_data = $multilang_row->get_columns;
        foreach my $attribute (keys %multilang_data)
        {
            if($attribute ne 'id' && $attribute ne $self->item_type() && $attribute ne 'language')
            {
                my $accessor = $self->can($attribute);
                if($accessor)
                {
                    $data{$attribute} = $self->$accessor($language);
                }
                else
                {
                    $data{$attribute} = $multilang_data{$attribute};
                }
            }
        } 
    }
    return %data;
}

sub main_title
{
    my $self = shift;
    if($self->row->result_source->has_column('title'))
    {
        return $self->get_attr('title');
    }
    elsif($self->row->result_source->has_column('name'))
    {
        return $self->get_attr('name');
    }   
    else
    {
        return "[". $self->get_attr('id') . "]";
    }
}
sub publish
{
    my $self = shift;
    return if ! $self->publishable();
    $self->row->published(1);
    $self->row->update();
}
sub unpublish
{
    my $self = shift;
    return if ! $self->publishable();
    $self->row->published(0);
    $self->row->update();
}
sub next_in_category_by_order
{
    my $self = shift;
    my $language = shift;
    my $category = schema->resultset('Category')->find( { category => $self->category() } );
    my $category_access = $self->category_accessor($category);
    my $criteria = { display_order => { '>', $self->get_attr('display_order') }};
    if($self->publishable())
    {
        $criteria->{'published'} = 1;
    }
 
    my @nexts = $category->$category_access->search($criteria, { order_by => {-asc => 'display_order' }});
    if($#nexts >= 0)
    {
        for(@nexts)
        {
            my $el = $self->new($_->id);
            if($el->has_language($language))
            {
                return $el;
            }
        }
    }
    return $self->new(undef);
}
sub prev_in_category_by_order
{
    my $self = shift;
    my $language = shift;
    my $category = schema->resultset('Category')->find( { category => $self->category() } );
    my $category_access = $self->category_accessor($category);
    my $criteria = { display_order => { '<', $self->get_attr('display_order') }};
    if($self->publishable())
    {
        $criteria->{'published'} = 1;
    }
    my @nexts = $category->$category_access->search($criteria, { order_by => {-desc => 'display_order' }});
    if($#nexts >= 0)
    {
        for(@nexts)
        {
            my $el = $self->new($_->id);
            if($el->has_language($language))
            {
                return $el;
            }
        }
    }
    return $self->new(undef);
}
sub next_in_category_by_date
{
    my $self = shift;
    my $language = shift;
    my $category = schema->resultset('Category')->find( { category => $self->category() } );
    my $category_access = $self->category_accessor($category);
    my $criteria = {publish_date => { '>', $self->get_attr('publish_date') }};
    if($self->publishable())
    {
        $criteria->{'published'} = 1;
    }
    my @nexts = $category->$category_access->search($criteria, { order_by => {-asc => 'publish_date' }});
    if($#nexts >= 0)
    {
        for(@nexts)
        {
            my $el = $self->new($_->id);
            if($el->has_language($language))
            {
                return $el;
            }
        }
    }
    return $self->new(undef);
}
sub prev_in_category_by_date
{
    my $self = shift;
    my $language = shift;
    my $category = schema->resultset('Category')->find( { category => $self->category() } );
    my $category_access = $self->category_accessor($category);
    my $criteria = { publish_date => { '<', $self->get_attr('publish_date') }};
    if($self->publishable())
    {
        $criteria->{'published'} = 1;
    }
    my @nexts = $category->$category_access->search($criteria , { order_by => {-desc => 'publish_date' }});
    if($#nexts >= 0)
    {
        for(@nexts)
        {
            my $el = $self->new($_->id);
            if($el->has_language($language))
            {
                return $el;
            }
        }
    }
    return $self->new(undef);
}
sub get_last_by_order
{
    my $self = shift;
    my $cat = shift;
    my $language = shift;
    my $category = schema->resultset('Category')->find( { id => $cat } );
    return undef if(! $category);
    my $category_access = $self->category_accessor($category);
    my $criteria = {};
    if($self->publishable())
    {
        $criteria = { published => 1 };
    }
    my @chapters = $category->$category_access->search($criteria , { order_by => { -desc => 'display_order' } });
    if($chapters[0])
    {
        for(@chapters)
        {
            my $el = $self->new($_->id);
            if($el->has_language($language))
            {
                return $el;
            }
        }
    }
    return undef;
}
sub get_last_by_date
{
    my $self = shift;
    my $cat = shift;
    my $language = shift;
    my $category = schema->resultset('Category')->find( { id => $cat } );
    return undef if(! $category);
    my $category_access = $self->category_accessor($category);
    my $criteria = {};
    if($self->publishable())
    {
        $criteria = { published => 1 };
    }
    my @chapters = $category->$category_access->search( $criteria, { order_by => { -desc => 'publish_date' } });
    if($chapters[0])
    {
        for(@chapters)
        {
            my $el = $self->new($_->id);
            if($el->has_language($language))
            {
                return $el;
            }
        }
    }
    return undef;
}
sub get_first_by_order
{
    my $self = shift;
    my $cat = shift;
    my $language = shift;
    my $category = schema->resultset('Category')->find( { id => $cat } );
    return undef if(! $category);
    my $category_access = $self->category_accessor($category);
    my $criteria = {};
    if($self->publishable())
    {
        $criteria = { published => 1 };
    }
    my @chapters = $category->$category_access->search( $criteria, { order_by => { -asc => 'display_order' } });
    if($chapters[0])
    {
        for(@chapters)
        {
            my $el = $self->new($_->id);
            if($el->has_language($language))
            {
                return $el;
            }
        }
    }
    return undef;
}
sub get_first_by_date
{
    my $self = shift;
    my $cat = shift;
    my $language = shift;
    my $category = schema->resultset('Category')->find( { id => $cat } );
    return undef if(! $category);
    my $category_access = $self->category_accessor($category);
    my $criteria = {};
    if($self->publishable())
    {
        $criteria = { published => 1 };
    }
    my @chapters = $category->$category_access->search( $criteria, { order_by => { -asc => 'publish_date' } });
    if($chapters[0])
    {
        for(@chapters)
        {
            my $el = $self->new($_->id);
            if($el->has_language($language))
            {
                return $el;
            }
        }
    }
    return undef;
}

sub get_list
{
    my $self = shift;
    my $params = shift;
    my %args = %{ $params };
    $args{'order'} ||= 'desc';
    $args{'order_by'} ||= 'id';
    $args{'entries_per_page'} ||= 20;
    $args{'page'} ||= 1;
    $args{'language'} ||= config->{Strehler}->{default_language};

    my $no_paging = 0;
    my $default_page = 1;
    if($args{'entries_per_page'} == -1)
    {
        $args{'entries_per_page'} = undef;
        $default_page = undef;
        $no_paging = 1;
    }

    my $search_criteria = undef;
    if($self->publishable())
    {
        if(exists $args{'published'})
        {
            $search_criteria->{'published'} = $args{'published'};
        }
    }
    if(exists $args{'tag'} && $args{'tag'})
    {
        my $ids = schema->resultset('Tag')->search({tag => $args{'tag'}, item_type => $self->item_type()})->get_column('item_id');
        $search_criteria->{'id'} = { -in => $ids->as_query };
    }

    my $rs;
    if(exists $args{'category_id'} && $args{'category_id'})
    {
        my $category = schema->resultset('Category')->find( { id => $args{'category_id'} } );
        if(! $category)
        {
            return {'to_view' => [], 'last_page' => 1 };
        }
        my $category_access = $self->category_accessor($category);
        $rs = $category->$category_access->search($search_criteria, { order_by => { '-' . $args{'order'} => $args{'order_by'} } , page => $default_page, rows => $args{'entries_per_page'} });
    }
    elsif(exists $args{'category'} && $args{'category'})
    {
        my $category;
        my $category_obj = Strehler::Meta::Category::explode_name($args{'category'});
        if(! $category_obj->exists())
        {
            return {'to_view' => [], 'last_page' => 1 };
        }
        else
        {
            $category = $category_obj->row;
        }
        my $category_access = $self->category_accessor($category);
        $rs = $category->$category_access->search($search_criteria, { order_by => { '-' . $args{'order'} => $args{'order_by'} } , page => $default_page, rows => $args{'entries_per_page'} });
    }
    else
    {
        $rs = schema->resultset($self->ORMObj())->search($search_criteria, { order_by => { '-' . $args{'order'} => $args{'order_by'} } , page => $default_page, rows => $args{'entries_per_page'}});
    }
    my $elements;
    my $last_page;
    if($no_paging)
    {
        $elements = $rs;
        $last_page = 1;
    }
    else
    {
        my $pager = $rs->pager();
        $elements = $rs->page($args{'page'});
        $last_page = $pager->last_page();
    }
    my @to_view;
    for($elements->all())
    {
        my $img = $self->new($_->id);
        my %el;
        if(exists $args{'ext'})
        {
            %el = $img->get_ext_data($args{'language'});
        }
        else
        {
            %el = $img->get_basic_data();
        }
        push @to_view, \%el;
    }
    return {'to_view' => \@to_view, 'last_page' => $last_page};
}

sub make_select
{
    my $self = shift;
    my $list = $self->get_list( {} );
    my @category_values_for_select;
    push @category_values_for_select, { value => undef, label => "-- seleziona --" }; 
    for(@{$list->{to_view}})
    {
        push @category_values_for_select, { value => $_->{'id'}, label => $_->{'title'} }
    }
    return \@category_values_for_select;
}

sub get_form_data
{
    my $self = shift;
    my $el_row = $self->row;
    my %columns = $el_row->get_columns;
    my $data = \%columns;
    foreach my $attribute (keys %columns)
    {
        if($el_row->result_source->column_info($attribute)->{'data_type'} eq 'timestamp')
        {
            $data->{$attribute} = $el_row->$attribute;
        }
    }
    if($self->row->can('category')) #Is the element categorized?
    {
        if($el_row->category->parent)
        {
            $data->{'category'} = $el_row->category->parent->id;
            $data->{'subcategory'} = $el_row->category->id;
        }
        else
        {
        $data->{'category'} = $el_row->category->id;
        }
    }
    my $children = $self->row->can($self->multilang_children());
    if($children)
    {
        my @multilang_rows = $self->row->$children;
        foreach my $ml (@multilang_rows)
        {
            my %ml_columns = $ml->get_columns;
            foreach my $k (keys %ml_columns)
            {
                if($k ne 'id' && $k ne $self->item_type() && $k ne 'language')
                {
                    foreach my $attribute (keys %columns)
                    {
                        my $data_to_save;
                        if($ml->result_source->column_info($k)->{'data_type'} eq 'timestamp')
                        {
                            $data_to_save = $ml->$attribute;
                        }
                        else
                        {
                            $data_to_save = $ml_columns{$k};
                        }
                        $data->{$k . '_' . $ml_columns{'language'}} = $data_to_save;
                    }
                }
            }
        }
    }
    return $data;
}

sub save_form
{
    my $self = shift;
    my $id = shift;
    my $form = shift;
    
    my $el_row;
    my $el_data;
    foreach my $column (schema->resultset($self->ORMObj())->result_source->columns)
    {
        if($column ne 'category' && $column ne 'id' && $column ne 'published')
        {
            if($form->param_value($column))
            {
                $el_data->{$column} = $form->param_value($column);
            }
            else
            {
                my $accessor = $self->can('save_' . $column);
                if($accessor)
                {
                    $el_data->{$column} = $self->$accessor($id, $form, undef);

                }
            }
        }
        elsif($column eq 'category')
        {
            my $category;
            if($form->param_value('subcategory'))
            {
                $category = $form->param_value('subcategory');
            }
            elsif($form->param_value('category'))
            {
                $category = $form->param_value('category');
            }
            $el_data->{'category'} = $category;
        }
    }
    my $children;
    if($id)
    {
        $el_row = schema->resultset($self->ORMObj())->find($id);
        $el_row->update($el_data);
        $children = $el_row->can($self->multilang_children());
        $el_row->$children->delete_all() if($children);
    }
    else
    {
        $el_row = schema->resultset($self->ORMObj())->create($el_data);
        $children = $el_row->can($self->multilang_children());
    }
    if($children)
    {
        my @languages = @{config->{Strehler}->{languages}};
        foreach my $lang (@languages)
        {
            my $to_write = 0;
            my $multi_el_data;
            foreach my $multicolumn (schema->resultset($self->ORMObj())->$children->result_source->columns)
            {
                if($form->param_value($multicolumn . '_' . $lang))
                {
                    $multi_el_data->{$multicolumn} = $form->param_value($multicolumn . '_' . $lang);
                    $to_write = 1;
                }    
                else
                {
                    my $accessor = $self->can('save_' . $multicolumn);
                    if($accessor)
                    {
                        $multi_el_data->{$multicolumn} = $self->$accessor($el_row->id, $form, $lang);
                    }
                    $to_write = 1 if $multi_el_data->{$multicolumn};
                }
            }
            if($to_write)
            {
                $multi_el_data->{'language'} = $lang;
                $el_row->$children->create( $multi_el_data );   
            }
        }
    }
    if($form->param_value('tags'))
    {
        Strehler::Meta::Tag->save_tags($form->param_value('tags'), $el_row->id, $self->item_type());
    }
    return $el_row->id;  
}

1;
