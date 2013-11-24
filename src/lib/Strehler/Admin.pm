package Strehler::Admin;

use Digest::MD5 "md5_hex";
use Dancer2;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::Ajax;
use HTML::FormFu;
use HTML::FormFu::Element::Block;
use Data::Dumper;
use Strehler::Helpers;
use Strehler::Element::Image;
use Strehler::Element::Article;
use Strehler::Element::Category;

prefix '/admin';
set layout => 'admin';

hook before => sub {
    return if(! config->{admin_secured});
    if((! session 'user') && request->path_info ne dancer_app->prefix . '/login')
    {
        session redir_url => request->path_info;
        my $redir = redirect(dancer_app->prefix . '/login');
        context->response->is_halted(0);
        return $redir;
        #redirect dancer_app->prefix . '/login';
    }
};

hook before_template_render => sub {
        my $tokens = shift;
        my $match_string = "^" . dancer_app->prefix . "\/(.*?)\/";
        my $match_regexp = qr/$match_string/;
        my $path = request->path_info();
        my $tab;
        if($path =~ $match_regexp)
        {
            $tab = $1;
        }
        else
        {
            $tab = 'home';
        }
        my %navbar;
        $navbar{$tab} = 'active';
        $tokens->{'navbar'} = \%navbar;
    };

my @languages = @{config->{languages}};


##### Homepage #####

get '/' => sub {
    my %navbar;
    $navbar{'home'} = "active";
    template "admin/index", { navbar => \%navbar};
};

##### Login #####

any '/login' => sub {
    my $form = HTML::FormFu->new;
    $form->load_config_file( 'forms/admin/login.yml' );
    my $params_hashref = params;
    $form->process($params_hashref);
    my $message;
    if($form->submitted_and_valid)
    {
        if(login_valid($params_hashref->{'user'}, $params_hashref->{'password'}))
        {
            session 'user' => $params_hashref->{'user'};
            if( session 'redir_url' )
            {
                my $redir = redirect(session 'redir_url');
                context->response->is_halted(0);
                return $redir;
                #redirect session 'redir_url';
            }
            else
            {
                my $redir = redirect(dancer_app->prefix . '/');
                context->response->is_halted(0);
                return $redir;
                #redirect dancer_app->prefix . '/';
            }
        }
        else
        {
            $message = "Authentication failed!";
        }
    }
    template "admin/login", { form => $form->render(), message => $message, layout => 'admin' }
};

##### Images #####

get '/image' => sub
{
    redirect dancer_app->prefix . '/image/list';
};

get '/image/list' => sub
{
    my $page = exists params->{'page'} ? params->{'page'} : session 'image-page';
    my $cat_param = exists params->{'cat'} ? params->{'cat'} : session 'image-cat-filter';
    if(exists params->{'catname'})
    {
        my $wanted_cat = Strehler::Element::Category::explode_name(params->{'catname'});
        $cat_param = $wanted_cat->get_attr('id');
    }
    $page ||= 1;
    my $cat = undef;
    my $subcat = undef;
    ($cat, $subcat) = Strehler::Element::Category::explode_tree($cat_param);
    my $entries_per_page = 20;
    my $elements = Strehler::Element::Image::get_list({ page => $page, entries_per_page => $entries_per_page, category_id => $cat_param});
    session 'image-page' => $page;
    session 'image-cat-filter' => $cat_param;
    template "admin/image_list", { images => $elements->{'to_view'}, page => $page, cat_filter => $cat, subcat_filter => $subcat, last_page => $elements->{'last_page'} };
};

any '/image/add' => sub
{
    my $form = form_image('add');
    my $params_hashref = params;
    $form = tags_for_form($form, $params_hashref);
    $form->process($params_hashref);
    if($form->submitted_and_valid)
    {
        my $img = request->upload('photo');
        my $id = Strehler::Element::Image::save_form(undef, $img, $form);
        redirect dancer_app->prefix . '/image/edit/' . $id;
    }
    $form = bootstrap_divider($form);
    template "admin/image", { form => $form->render() }
};

get '/image/delete/:id' => sub
{
    my $id = params->{id};
    my $img = Strehler::Element::Image->new($id);
    my %image = $img->get_basic_data();
    template "admin/delete", { what => "l'immagine", el => \%image, , backlink => dancer_app->prefix . '/image' };
};
post '/image/delete/:id' => sub
{
    my $id = params->{id};
    my $image = Strehler::Element::Image->new($id);
    $image->delete();
    redirect dancer_app->prefix . '/image/list';
};


get '/image/edit/:id' => sub {
    my $id = params->{id};
    my $image = Strehler::Element::Image->new($id);
    my $form_data = $image->get_form_data();
    my $form = form_image('edit', $form_data->{'category'});
    $form->default_values($form_data);
    $form = bootstrap_divider($form);
    template "admin/image", { id => $id, form => $form->render(), img_source => $image->get_attr('image') }
};

post '/image/edit/:id' => sub
{
    my $form = form_image('edit');
    my $id = params->{id};
    my $params_hashref = params;
    $form = tags_for_form($form, $params_hashref);
    $form->process($params_hashref);
    my $message;
    if($form->submitted_and_valid)
    {
        my $img = request->upload('photo');
        Strehler::Element::Image::save_form($id, $img, $form);
        redirect dancer_app->prefix . '/image/list';
    }
    my $img = Strehler::Element::Image->new($id);
    $form = bootstrap_divider($form);
    template "admin/image", { form => $form->render(),img_source => $img->get_attr('image') }
};

ajax '/image/src/:id' => sub
{
    my $id = params->{id};
    my $img = Strehler::Element::Image->new($id);
    return $img->get_attr('image');
};

ajax '/image/tagform/:id?' => sub
{
    if(params->{id})
    {
        my $image = Strehler::Element::Image->new(params->{id});
        my @category_tags = Strehler::Element::Tag::get_configured_tags_for_template($image->get_attr('category'), 'image');
        my @tags = split(',', $image->get_tags());
        my @out;
        if($#category_tags > -1)
        {
            foreach my $c_t (@category_tags)
            {
                my $default = 0;
                if (grep {$_ eq $c_t->tag} @tags) 
                {
                    $default = 1;
                }
                push @out, { tag => $c_t->tag, default_tag => $default };
            }
            template 'admin/configured_tags', { tags => \@out };
        }
        else
        {
            template 'admin/open_tags';
        }
    }
    else
    {
           template 'admin/open_tags';
    }
};


##### Articles #####

get '/article' => sub
{
    redirect dancer_app->prefix . '/article/list';
};

get '/article/list' => sub
{
    my $page = exists params->{'page'} ? params->{'page'} : session 'article-page';
    my $cat_param = exists params->{'cat'} ? params->{'cat'} : session 'article-cat-filter';
    if(exists params->{'catname'})
    {
        my $wanted_cat = Strehler::Element::Category::explode_name(params->{'catname'});
        $cat_param = $wanted_cat->get_attr('id');
    }
    $page ||= 1;
    my $cat = undef;
    my $subcat = undef;
    ($cat, $subcat) = Strehler::Element::Category::explode_tree($cat_param);
    my $entries_per_page = 20;
    my $elements = Strehler::Element::Article::get_list({ page => $page, entries_per_page => $entries_per_page, category_id => $cat_param});
    session 'article-page' => $page;
    session 'article-cat-filter' => $cat_param;
    template "admin/article_list", { articles => $elements->{'to_view'}, page => $page, cat_filter => $cat, subcat_filter => $subcat, last_page => $elements->{'last_page'} };

};


any '/article/add' => sub
{
    my $form = form_article(); 
    my $params_hashref = params;
    $form = tags_for_form($form, $params_hashref);
    $form->process($params_hashref);
    if($form->submitted_and_valid)
    {
        Strehler::Element::Article::save_form(undef, $form);
        redirect dancer_app->prefix . '/article/list';
    }
    my $fake_tags = $form->get_element({ name => 'tags'});
    $form->remove_element($fake_tags) if($fake_tags);
    template "admin/article", { form => $form->render() }
};

get '/article/edit/:id' => sub {
    my $id = params->{id};
    my $article = Strehler::Element::Article->new($id);
    my $form_data = $article->get_form_data();
    my $form = form_article($form_data->{'category'});
    $form->default_values($form_data);
    template "admin/article", { id => $id, form => $form->render() }
};

post '/article/edit/:id' => sub
{
    my $form = form_article();
    my $id = params->{id};
    my $params_hashref = params;
    $form = tags_for_form($form, $params_hashref);
    $form->process($params_hashref);
    if($form->submitted_and_valid)
    {
        Strehler::Element::Article::save_form($id, $form);
        redirect dancer_app->prefix . '/article/list';
    }
    template "admin/article", { form => $form->render() }
};

get '/article/delete/:id' => sub
{
    my $id = params->{id};
    my $art = Strehler::Element::Article->new($id);
    my %article = $art->get_basic_data();
    template "admin/delete", { what => "l'articolo", el => \%article, , backlink => dancer_app->prefix . '/article' };
};
post '/article/delete/:id' => sub
{
    my $id = params->{id};
    my $article = Strehler::Element::Article->new($id);
    $article->delete();
    redirect dancer_app->prefix . '/article/list';
};
get '/article/turnon/:id' => sub
{
    my $id = params->{id};
    my $article = Strehler::Element::Article->new($id);
    $article->publish();
    redirect dancer_app->prefix . '/article/list';
};
get '/article/turnoff/:id' => sub
{
    my $id = params->{id};
    my $article = Strehler::Element::Article->new($id);
    $article->unpublish();
    redirect dancer_app->prefix . '/article/list';
};
ajax '/article/tagform/:id?' => sub
{
    if(params->{id})
    {
        my $article = Strehler::Element::Article->new(params->{id});
        my @category_tags = Strehler::Element::Tag::get_configured_tags_for_template($article->get_attr('category'), 'article');
        my @tags = split(',', $article->get_tags());
        my @out;
        if($#category_tags > -1)
        {
            foreach my $c_t (@category_tags)
            {
                my $default = 0;
                if (grep {$_ eq $c_t->tag} @tags) 
                {
                    $default = 1;
                }
                push @out, { tag => $c_t->tag, default_tag => $default };
            }
            template 'admin/configured_tags', { tags => \@out };
        }
        else
        {
            template 'admin/open_tags';
        }
    }
    else
    {
           template 'admin/open_tags';
    }
};

#Categories

get '/category' => sub
{
    redirect dancer_app->prefix . '/category/list';
};

any '/category/list' => sub
{
    #THE TABLE
    my $to_view = Strehler::Element::Category::get_list();

    #THE FORM
    my $form = HTML::FormFu->new;
    $form->load_config_file( 'forms/admin/category_fast.yml' );
    my $parent = $form->get_element({ name => 'parent'});
    $parent->options(Strehler::Element::Category::make_select());
    my $params_hashref = params;
    $form->process($params_hashref);
    if($form->submitted_and_valid)
    {
        my $new_category = Strehler::Element::Category::save_form(undef, $form);
        redirect dancer_app->prefix . '/category/list';
    }
    template "admin/category_list", { categories => $to_view, form => $form };
};

any '/category/add' => sub
{
    my $form = form_category();
    my $params_hashref = params;
    $form->process($params_hashref);
    if($form->submitted_and_valid)
    {
        Strehler::Element::Category::save_form(undef, $form);
        redirect dancer_app->prefix . '/category/list'; 
    }
    $form = bootstrap_divider($form);
    template "admin/category", { form => $form->render() }
};
get '/category/edit/:id' => sub {
    my $id = params->{id};
    my $category = Strehler::Element::Category->new($id);
    my $form_data = $category->get_form_data();
    my $form = form_category();
    $form->default_values($form_data);
    template "admin/category", { form => $form->render() }
};
post '/category/edit/:id' => sub
{
    my $form = form_category();
    my $id = params->{id};
    my $params_hashref = params;
    $form->process($params_hashref);
    if($form->submitted_and_valid)
    {
        Strehler::Element::Category::save_form($id, $form);
        redirect dancer_app->prefix . '/category/list';
    }
    template "admin/category", { form => $form->render() }
};

get '/category/delete/:id' => sub
{
    my $id = params->{id};
    my $category = Strehler::Element::Category->new($id);
    if($category->has_elements())
    {
        my $message = "La categoria " . $category->get_attr('category') . " non &egrave; vuota! Non &egrave; possibile cancellarla";    
        my $return = dancer_app->prefix . "/category/list";
        template "admin/message", { message => $message, backlink => $return };
    }
    else
    {
        my %data = $category->get_basic_data();
        template "admin/delete", { what => "la categoria", el => \%data, backlink => dancer_app->prefix . '/category' };
    }
};
post '/category/delete/:id' => sub
{
    my $id = params->{id};
    my $category = Strehler::Element::Category->new($id);
    $category->delete();
    redirect dancer_app->prefix . '/category/list';
};

ajax '/category/last/:id' => sub
{
    my $id = params->{id};
    my $category = Strehler::Element::Category->new($id);
    return $category->max_article_order() + 1;
};
get '/category/select/:id' => sub
{
    my $id = params->{id};
    my $data = Strehler::Element::Category::make_select($id);
    if($data->[1])
    {
        template 'admin/category_select', { categories => $data }, { layout => undef };
    }
    else
    {
        return 0;
    }
};
get '/category/select' => sub
{
    my $data = Strehler::Element::Category::make_select(undef);
    if($data->[1])
    {
        template 'admin/category_select', { categories => $data }, { layout => undef };
    }
    else
    {
        return 0;
    }
};
ajax '/category/tagform/:type/:id?' => sub
{
    if(params->{id})
    {
        my @tags = Strehler::Element::Tag::get_configured_tags_for_template(params->{id}, params->{type});
        if($#tags > -1)
        {
           template 'admin/configured_tags', { tags => \@tags };
        }
        else
        {
            template 'admin/open_tags';
        }
    }
    else
    {
        template 'admin/open_tags';
    }
};

##### Helpers #####
# They only manipulate forms rendering and manage login

sub login_valid
{
    my $user = shift;
    my $password = shift;
    my $hashed = md5_hex($password);
    my $rs = schema->resultset('User')->find({'user' => $user, 'password' => $hashed});
    if($rs)
    {
        return 1;
    }
    else
    {
        return 0;
    }
        
}

sub form_image
{
    my $action = shift;
    my $has_sub = shift;
    my $form = HTML::FormFu->new;
    $form->load_config_file( 'forms/admin/image.yml' );
    $form = add_multilang_fields($form, \@languages, 'forms/admin/image_multilang.yml'); 
    $form->constraint({ name => 'photo', type => 'Required' }) if $action eq 'add';
    my $category = $form->get_element({ name => 'category'});
    $category->options(Strehler::Element::Category::make_select());
    my $subcategory = $form->get_element({ name => 'subcategory'});
    $subcategory->options(Strehler::Element::Category::make_select($has_sub));
    return $form;
}

sub form_article
{
    my $has_sub = shift;
    my $form = HTML::FormFu->new;
    $form->load_config_file( 'forms/admin/article.yml' );
    $form = add_multilang_fields($form, \@languages, 'forms/admin/article_multilang.yml'); 
    my $default_language = config->{default_language};
    $form->constraint({ name => 'title_' . $default_language, type => 'Required' }); 
    #$form->constraint({ name => 'text_' . $default_language, type => 'Required' }); 
    my $image = $form->get_element({ name => 'image'});
    $image->options(Strehler::Element::Image::make_select());
    my $category = $form->get_element({ name => 'category'});
    $category->options(Strehler::Element::Category::make_select());
    my $subcategory = $form->get_element({ name => 'subcategory'});
    $subcategory->options(Strehler::Element::Category::make_select($has_sub));
    return $form;
}

sub form_category
{
    my $form = HTML::FormFu->new;
    $form->load_config_file( 'forms/admin/category.yml' );
    my $category = $form->get_element({ name => 'parent'});
    $category->options(Strehler::Element::Category::make_select());
    return $form;
}
sub tags_for_form
{
    my $form = shift;
    my $params_hashref = shift;
    if($params_hashref->{'configured-tag'})
    {
        if(ref($params_hashref->{'configured-tag'}) eq 'ARRAY')
        {
            $params_hashref->{'tags'} = join(',', @{$params_hashref->{'configured-tag'}});
        }
        else
        {
            $params_hashref->{'tags'} = $params_hashref->{'configured-tag'};
        }
        my $subcategory = $form->get_element({ name => 'subcategory'});
        $form->insert_after($form->element({ type => 'Text', name => 'tags'}), $subcategory);
    }
    elsif($params_hashref->{'tags'})
    { 
        my $subcategory = $form->get_element({ name => 'subcategory'});
        $form->insert_after($form->element({ type => 'Text', name => 'tags'}), $subcategory);
    }
    return $form;
}

sub bootstrap_divider
{
    my $form = shift;
    my $elements = $form->get_elements();
    my $divider = HTML::FormFu::Element::Block->new({ type => 'Block', tag => 'div', content => '&nbsp;' });
    $divider->add_attributes({class => 'divider'});
    foreach(@{$elements})
    {
        my $el = $_;
        $form->insert_after($divider->clone(), $el);
    }
    return $form;
}

sub add_multilang_fields
{
    my $form = shift;
    my $lan_ref = shift;
    my $config = shift;
    my $position = $form->get_element({ name => 'save' });
    for(@{$lan_ref})
    {
        my $lan = $_;
        my $form_multilan = HTML::FormFu->new;
        $form_multilan->load_config_file($config);
        for(@{$form_multilan->get_elements()})
        {
            my $el = $_;
            $el->name($el->name() . '_' . $lan);
            $el->label($el->label . " (" . $lan . ")");
            $form->insert_before($_->clone(), $position);
        }
    }
    return $form;
}


1;
