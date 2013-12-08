package Strehler::Element;

use Moo;
use Dancer2;
use Dancer2::Plugin::DBIC;
use Strehler::Meta::Tag;

use Data::Dumper;

has row => (
    is => 'ro',
);

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
    $self->row->delete();
    $self->row->$children->delete_all();
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
    return 0 if not $children;
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
sub category
{
    my $self = shift;
    return $self->row->category->category;
}
sub get_tags
{
    my $self = shift;
    my $tags = Strehler::Meta::Tag::tags_to_string($self->get_attr('id'), $self->item_type());
    return $tags;
}

sub category_accessor
{
    my $self = shift;
    my $category = shift;
    print "Call in father";
    return undef;
}

sub item_type
{
    return "generic";
}


sub next_in_category_by_order
{
    my $self = shift;
    my $language = shift;
    my $category = schema->resultset('Category')->find( { category => $self->category() } );
    my $category_access = $self->category_accessor($category);
    my $criteria = { display_order => { '>', $self->get_attr('display_order') }};
    if($self->can('publish'))
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
    if($self->can('publish'))
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
    if($self->can('publish'))
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
    if($self->can('publish'))
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
    my $category = schema->resultset('Category')->find( { category => $cat } );
    return undef if(! $category);
    my $category_access = $self->category_accessor($category);
    my $criteria = {};
    if($self->can('publish'))
    {
        $criteria = { published => 1 };
    }
    my @chapters = $category->$category_access->search($criteria , { order_by => { -desc => 'display_order' } });
    if($chapters[0])
    {
        return $self->new($chapters[0]->id);
    }
    else
    {
        return undef;
    }
}
sub get_last_by_date
{
    my $self = shift;
    my $cat = shift;
    my $category = schema->resultset('Category')->find( { category => $cat } );
    return undef if(! $category);
    my $category_access = $self->category_accessor($category);
    my $criteria = {};
    if($self->can('publish'))
    {
        $criteria = { published => 1 };
    }
    my @chapters = $category->$category_access->search( $criteria, { order_by => { -desc => 'publish_date' } });
    if($chapters[0])
    {
        return $self->new($chapters[0]->id);
    }
    else
    {
        return undef;
    }
}
sub get_first_by_order
{
    my $self = shift;
    my $cat = shift;
    my $category = schema->resultset('Category')->find( { category => $cat } );
    return undef if(! $category);
    my $category_access = $self->category_accessor($category);
    my $criteria = {};
    if($self->can('publish'))
    {
        $criteria = { published => 1 };
    }
    my @chapters = $category->$category_access->search( $criteria, { order_by => { -asc => 'display_order' } });
    if($chapters[0])
    {
        return $self->new($chapters[0]->id);
    }
    else
    {
        return undef;
    }
}
sub get_first_by_date
{
    my $self = shift;
    my $cat = shift;
    my $category = schema->resultset('Category')->find( { category => $cat } );
    return undef if(! $category);
    my $category_access = $self->category_accessor($category);
    my $criteria = {};
    if($self->can('publish'))
    {
        $criteria = { published => 1 };
    }
    my @chapters = $category->$category_access->search( $criteria, { order_by => { -asc => 'publish_date' } });
    if($chapters[0])
    {
        return $self->new($chapters[0]->id);
    }
    else
    {
        return undef;
    }
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
    if($self->can('publish'))
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

1;
