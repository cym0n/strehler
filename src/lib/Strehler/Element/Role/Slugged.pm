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
        my @chapters = $self->get_schema()->resultset($self->ORMObj())->search({ $children . '.slug' => $slug, $children . '.language' => $language }, { join => $children });
        $chapter = $chapters[0];
    }
    else
    {
        $chapter = $self->get_schema()->resultset($self->ORMObj())->find({ slug => $slug });
    }
    if($chapter)
    {
        return $self->new($chapter->id);
    }
    else
    {
        return undef;
    }
}

1;

=encoding utf8

=head1 NAME

Strehler::Element::Role::Slugged - A role to manage element's slug

=head1 DESCRIPTION

A slugged Strehler element provides an authomatic management of a slug (multilanguage or not). Slug can then be used to retrieve the element itself.

Default implementation that come with the role is the one used by L<Strehler::Element::Article> but methods can be overridden for different behaviours.

A slugged element must include, in its database representation, a field named slug (VARCHAR), in the main table or in the table of multilanguage contents.

=head1 SYNOPSIS

    my $article = Strehler::Element::Article->get_by_slug('a-slug-suitable-for-web', $language)

=head1 FUNCTIONS

=over 4

=item multilang_slug

Return 1 if the slug is multilanguage and comes from the multilanguage contents table.

=item to_slug

Return the field, from the form, that will be used to make the slug.

=item save_slug

Hook used by save_form method from L<Strehler::Element>. 

It takes the field with the name returned by to_slug from the POSTed form and create a slug from it using L<Strehler::Helpers> slugify function.

Slug is guaranteed unique because, in any case, element ID is preferred to the slug string.

=item get_by_slug

Function to retrieve elements using slug.

An element that implements this method returns true when slugged() function (L<Strehler::Element::Role::Configured>) is called.

