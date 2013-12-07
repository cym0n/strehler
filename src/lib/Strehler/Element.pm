package Strehler::Element;

use Moo;
use Dancer2;
use Dancer2::Plugin::DBIC;

has row => (
    is => 'ro',
);
has type => (
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
    my $children = $self->row->can($self->multilang_children);
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
    my $children = $self->row->can($self->multilang_children);
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
    my $children = $self->row->can($self->multilang_children);
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
    my $tags = Strehler::Element::Tag::tags_to_string($self->get_attr('id'), $self->type);
    return $tags;
}

sub category_accessor
{
    my $self = shift;
    my $category = shift;
    print "Call in father";
    return undef;
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


1;
