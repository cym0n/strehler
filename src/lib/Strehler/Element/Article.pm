package Strehler::Element::Article;

use strict;
use Cwd 'abs_path';
use Moo;
use Dancer2 0.154000;
use Dancer2::Plugin::DBIC;

extends 'Strehler::Element';
with 'Strehler::Element::Role::Slugged';


my $module_file_path = __FILE__;
my $root_path = abs_path($module_file_path);
$root_path =~ s/Article\.pm//;
my $form_path = $root_path . "../forms";
my $views_path = $root_path . "../views";

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
    my $self = shift;
    return $self->_property('label', 'Articles');
}
sub categorized
{
    my $self = shift;
    return $self->_property('categorized', 1);
}
sub ordered
{
    my $self = shift;
    return $self->_property('ordered', 1);
}
sub dated
{
    my $self = shift;
    return $self->_property('dated', 1);
}
sub publishable
{
    my $self = shift;
    return $self->_property('publishable', 1);
}
sub class
{
    return __PACKAGE__;
}

sub form
{
    return $form_path . '/admin/article.yml';
}
sub multilang_form
{
    return $form_path . '/admin/article_multilang.yml';
}

sub add_main_column_span
{
    my $self = shift;
    return $self->_property('add_main_column_span', 9);
}
sub custom_snippet_add_position
{
    my $self = shift;
    return $self->_property('custom_snippet_position', 'right');
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

sub form_modifications
{
    my $self = shift;
    my $form = shift;
    my $default_language = config->{Strehler}->{default_language};
    $form->constraint({ name => 'title_' . $default_language, type => 'Required' }); 
    return $form;    
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

sub custom_add_snippet
{
    return '<div class="thumbnail"><img id="image_preview" src="/strehler/images/no-image.png" /></div>';
}
sub entity_js
{
    my $self = shift;
    return $self->_property('entity_js', '/strehler/js/article.js');
}
sub install
{
    return "Standard entity. No installation is needed.";
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







