package Strehler::Element::Article;


use Moo;
use Dancer2;
use Dancer2::Plugin::DBIC;
use Data::Dumper;

extends 'Strehler::Element';


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
        $article = schema->resultset('Article')->find($id);
   }
   return { row => $article };
};

sub get_form_data
{
    my $self = shift;
    my $article_row = $self->row;
    my @contents = $article_row->contents;
    my $data;
    if($article_row->category->parent_category)
    {
        $data->{'category'} = $article_row->category->parent_category->id;
        $data->{'subcategory'} = $article_row->category->id;
    }
    else
    {
       $data->{'category'} = $article_row->category->id;
    }
    $data->{'image'} = $article_row->image;
    $data->{'order'} = $article_row->display_order;
    $data->{'publish_date'} = $article_row->publish_date;
    for(@contents)
    {
        my $d = $_;
        my $lan = $d->language;
        $data->{'title_' . $lan} = $d->title;
        $data->{'text_' . $lan} = $d->text;
    }
    $data->{'tags'} = Strehler::Meta::Tag::tags_to_string($self->get_attr('id'), 'article');
    return $data;
}
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
sub get_basic_data
{
    my $self = shift;
    my %data;
    $data{'id'} = $self->get_attr('id');
    $data{'title'} = $self->main_title;
    $data{'category'} = $self->row->category->category;
    $data{'display_order'} = $self->get_attr('display_order');
    $data{'published'} = $self->get_attr('published');
    return %data;
}
sub get_ext_data
{
    my $self = shift;
    my $language = shift;
    my %data;
    %data = $self->get_basic_data();
    $data{'title'} = $self->get_attr_multilang('title', $language);
    $data{'slug'} = $self->get_attr_multilang('slug', $language);
    $data{'text'} = $self->get_attr_multilang('text', $language);
    $data{'display_order'} = $self->get_attr('display_order');
    $data{'publish_date'} = $self->publish_date();
    my $image = Strehler::Element::Image->new($self->get_attr('image'));
    if($image->exists())
    {
        $data{'image'} = $image->get_attr('image');
    }
    return %data;
}


sub publish
{
    my $self = shift;
    $self->row->published(1);
    $self->row->update();
}
sub unpublish
{
    my $self = shift;
    $self->row->published(0);
    $self->row->update();
}

#Ad hoc accessor to return the DateTime object
sub publish_date
{
    my $self = shift;
    return $self->row->publish_date;
}

#Category accessor used by static methods
sub category_accessor
{
    my $self = shift;
    my $category = shift;
    return $category->can('articles');
}

sub item_type
{
    return "article";
}

sub ORMObj
{
    return "Article";
}
sub multilang_children
{
    return 'contents';
}

sub get_by_slug
{
    my $self = shift;
    my $slug = shift;
    my $language = shift;
    my $chapter = schema->resultset('Content')->find({ slug => $slug, language => $language });
    if($chapter)
    {
        return Strehler::Element::Article->new($chapter->article->id);
    }
    else
    {
        return undef;
    }
}




sub save_form
{
    my $id = shift;
    my $form = shift;
    
    my $article_row;
    my $order;
    my $category = undef;
    if($form->param_value('subcategory'))
    {
        $category = $form->param_value('subcategory');
    }
    elsif($form->param_value('category'))
    {
        $category = $form->param_value('category');
    }
    if($category)
    {
        $order = $form->param_value('order');
    }
    else
    {
        $order = undef;
    }
    my $article_data ={ image => $form->param_value('image'), category => $category, display_order => $order, publish_date => $form->param_value('publish_date') };
    if($id)
    {
        $article_row = schema->resultset('Article')->find($id);
        $article_row->update($article_data);
        $article_row->contents->delete_all();
    }
    else
    {
        $article_row = schema->resultset('Article')->create($article_data);
    }
    my @languages = @{config->{Strehler}->{languages}};
    for(@languages)
    {
        my $lan = $_;
        my $title;
        my $text;
        if($form->param_value('title_' . $lan) =~ /^ *$/)
        {
            $title = undef;
        }
        else
        {
            $title = $form->param_value('title_' . $lan);
        }
        if($form->param_value('text_' . $lan) =~ /^ *$/)
        {
            $text = undef;
        }
        else
        {
            $text = $form->param_value('text_' . $lan);
        }
        if($title)
        {
            my $slug = $article_row->id . '-' . Strehler::Helpers::slugify($form->param_value('title_' . $lan));
            $article_row->contents->create( { title => $title, text => $text, slug => $slug, language => $lan }) 
        }
    }
    if($form->param_value('tags'))
    {
        Strehler::Meta::Tag::save_tags($form->param_value('tags'), $article_row->id, 'article');
    }
    return $article_row->id;  
}


1;







