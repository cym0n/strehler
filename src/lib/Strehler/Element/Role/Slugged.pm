package Strehler::Element::Role::Slugged;

use Moo::Role;
use Dancer2;
use Strehler::Helpers;

sub to_slug
{
    my $self = shift;
    my $lan = shift;
    return 'title_' . $lan;
}

sub multilang_slug
{
    return 1;
}

sub save_slug
{
    my $self = shift;
    my $id = shift;
    my $form = shift;
    my $lan = shift;
    my $slug_param = $self->to_slug($lan);
    if($form->param_value($slug_param))
    {
        return $id . '-' . Strehler::Helpers::slugify($form->param_value($slug_param));
    }
    else
    {
        return undef;
    }
}

sub get_by_slug
{
    my $self = shift;
    my $slug = shift;
    my $language = shift;

    my $chapter;
    if($self->multilang_slug())
    {
        my $children = $self->multilang_children();
        my @chapters = $self->get_schema()->resultset($self->ORMObj())->search_related($children, { slug => $slug, language => $language });
        $chapter = $chapters[0];
    }
    else
    {
        $chapter = $self->get_schema()->resultset($self->ORMObj())->find({ slug => $slug });
    }
    if($chapter)
    {
        return $self->new($chapter->article->id);
    }
    else
    {
        return undef;
    }
}
