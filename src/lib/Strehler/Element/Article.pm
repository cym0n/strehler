package Strehler::Element::Article;


use Moo;
use Dancer2 0.11;
use Dancer2::Plugin::DBIC;

extends 'Strehler::Element';
with 'Strehler::Element::Role::Slugged';

#Standard element implementation

sub metaclass_data 
{
    my $self = shift;
    my $param = shift;
    my %element_conf = ( item_type => 'article',
                         ORMObj => 'Article',
                         category_accessor => 'articles',
                         multilang_children => 'contents' );
    return $element_conf{$param};
}


#Standard configuration overrides

sub label
{
    return config->{'Strehler'}->{'extra_menu'}->{'article'}->{label} || "Articles";
}
sub categorized
{
    return config->{'Strehler'}->{'extra_menu'}->{'article'}->{categorized} || 1;
}
sub ordered
{
    return config->{'Strehler'}->{'extra_menu'}->{'article'}->{ordered} || 1;
}
sub dated
{
    return config->{'Strehler'}->{'extra_menu'}->{'article'}->{dated} || 1;
}
sub publishable
{
    return config->{'Strehler'}->{'extra_menu'}->{'article'}->{publishable} || 1;
}
sub class
{
    return __PACKAGE__;
}

#Main title redefined to fetch title from multilang attributes

sub main_title
{
    my $self = shift;
    my @contents = $self->row->contents->search({ language => config->{Strehler}->{default_language} });
    if($contents[0])
    {
        return $contents[0]->title;
    }
    else
    {
        #Should not be possible
        return "*** no title ***";
    }

}

sub fields_list
{
    my $self = shift;
    my @fields = ( { 'id' => 'id',
                     'label' => 'ID',
                     'ordinable' => 1 },
                   { 'id' => 'contents.title',
                     'label' => 'Title',
                     'ordinable' => 1 },
                   { 'id' => 'category',
                       'label' => 'Category',
                       'ordinable' => 0 },
                   { 'id' => 'display_order',
                     'label' => 'Order',
                     'ordinable' => 1 },
                   { 'id' => 'publish_date',
                     'label' => 'Date',
                     'ordinable' => 1 },
                   { 'id' => 'published',
                     'label' => 'Status',
                     'ordinable' => 1 }
                );
    return \@fields;
}
sub search_box
{
    my $self = shift;
    my $string = shift;
    my $parameters = shift;
    $parameters->{'search'} = { -or => [ 'contents.title' => { 'like', "%$string%" },
                                         'contents.text'  => { 'like', "%$string%" } ] 
                              };
    $parameters->{'join'} = 'contents';
    return $self->get_list($parameters);
}


#Ad hoc accessors and hooks
sub image
{
    my $self = shift;
    my $image = Strehler::Element::Image->new($self->row->image);
    if($image->exists())
    {
       return $image->get_attr('image');
    }
    else
    {
        return undef;
    }
}

=encoding utf8

=head1 NAME

Strehler::Element::Article - Strehler Entity for articles

=head1 DESCRIPTION

Base Strehler content, it's used to create general articles, multilanguage.

Its main title is the title in the language configured as default.

=head1 FEATURES

It implements L<Strehler::Element::Role::Slugged> so you can use slugs to refer to articles


=cut

1;







