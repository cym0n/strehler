package Admin;

use Digest::MD5 "md5_hex";
use Dancer2;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::Ajax;
use HTML::FormFu;
use HTML::FormFu::Element::Block;
use Data::Dumper;

prefix '/admin';
set layout => 'admin';

hook before => sub {
    return;
    if((! session 'user') && request->path_info ne dancer_app->prefix . '/login')
    {
        session redir_url => request->path_info;
        redirect dancer_app->prefix . '/login';
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

my @languages = ('it', 'en');


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
                redirect session 'redir_url';
            }
            else
            {
                redirect dancer_app->prefix . '/';
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
    my $page = params->{'page'} || 1;
    my $entries_per_page = 20;
    my @to_view;
    my $rs = schema->resultset('Image')->search(undef, { page => 1, rows => $entries_per_page});
    my $pager = $rs->pager();
    my $elements = $rs->page($page);
    for($elements->all())
    {
        my $row = $_;
        my %el;
        $el{'id'} = $row->id;
        $el{'source'} = $row->image;
        $el{'title'} = $row->main_title();
        $el{'category'} = $row->category->category;
        push @to_view, \%el;
    }
    template "admin/image_list", { images => \@to_view, page => $page, last_page => $pager->last_page() };
};

any '/image/add' => sub
{
    my $form = form_image('add');
    my $params_hashref = params;
    $form->process($params_hashref);
    my $message;
    if($form->submitted_and_valid)
    {
        my $img = request->upload('photo');
        my $id = save_image(undef, $img, $form);
        redirect dancer_app->prefix . '/image/edit/' . $id;
    }
    $form = bootstrap_divider($form);
    template "admin/image", { form => $form->render(), message => $message }
};

get '/image/delete/:id' => sub
{
    my $id = params->{id};
    my $img_row = schema->resultset('Image')->find($id);
    my %image;
    $image{'id'} = $id;
    $image{'title'} = $img_row->main_title;
    template "admin/delete", { what => "l'immagine", el => \%image, , backlink => dancer_app->prefix . '/image' };
};
post '/image/delete/:id' => sub
{
    my $id = params->{id};
    my $img_row = schema->resultset('Image')->find($id);
    $img_row->delete();
    $img_row->descriptions->delete_all();
    redirect dancer_app->prefix . '/image/list';
};


get '/image/edit/:id' => sub {
    my $form = form_image('edit');
    my $id = params->{id};
    my $img_row = schema->resultset('Image')->find($id);
    my @descriptions = $img_row->descriptions;
    my $data;
    $data->{'category'} = $img_row->category->id;
    for(@descriptions)
    {
        my $d = $_;
        my $lan = $d->language;
        $data->{'title_' . $lan} = $d->title;
        $data->{'description_' . $lan} = $d->description;
    }
    $form->default_values($data);
    $form = bootstrap_divider($form);
    template "admin/image", { form => $form->render(), img_source => $img_row->image }
};

post '/image/edit/:id' => sub
{
    my $form = form_image('edit');
    my $id = params->{id};
    my $params_hashref = params;
    $form->process($params_hashref);
    my $message;
    if($form->submitted_and_valid)
    {
        my $img = request->upload('photo');
        save_image($id, $img, $form);
        redirect dancer_app->prefix . '/image/list';
    }
    my $img_row = schema->resultset('Image')->find($id);
    $form = bootstrap_divider($form);
    template "admin/image", { form => $form->render(),img_source => $img_row->image }
};

ajax '/image/src/:id' => sub
{
    my $id = params->{id};
    my $img_row = schema->resultset('Image')->find($id);
    return $img_row->image;
};


##### Articles #####

get '/article' => sub
{
    redirect dancer_app->prefix . '/article/list';
};

get '/article/list' => sub
{
    my $page = params->{'page'} || 1;
    my $entries_per_page = 20;
    my @to_view;
    my $rs = schema->resultset('Article')->search(undef, { page => 1, rows => $entries_per_page});
    my $pager = $rs->pager();
    my $elements = $rs->page($page);
    for($elements->all())
    {
        my $row = $_;
        my %el;
        $el{'id'} = $row->id;
        $el{'title'} = $row->main_title();
        $el{'category'} = $row->category->category;
        $el{'display_order'} = $row->display_order;
        $el{'published'} = $row->published;
        push @to_view, \%el;
    }
    template "admin/article_list", { articles => \@to_view, page => $page, last_page => $pager->last_page() };
};


any '/article/add' => sub
{
    my $form = form_article(); 
    my $params_hashref = params;
    $form->process($params_hashref);
    my $message;
    if($form->submitted_and_valid)
    {
        my $id = save_article(undef, $form);
        redirect dancer_app->prefix . '/article/list';
    }
    template "admin/article", { form => $form->render(), message => $message }
};

get '/article/edit/:id' => sub {
    my $form = form_article();
    my $id = params->{id};
    my $article_row = schema->resultset('Article')->find($id);
    my @contents = $article_row->contents;
    my $data;
    $data->{'category'} = $article_row->category->id;
    $data->{'image'} = $article_row->image;
    $data->{'order'} = $article_row->display_order;
    for(@contents)
    {
        my $d = $_;
        my $lan = $d->language;
        $data->{'title_' . $lan} = $d->title;
        $data->{'slug_' . $lan} = $d->slug;
        $data->{'text_' . $lan} = $d->text;
    }
    $form->default_values($data);
    template "admin/article", { form => $form->render() }
};

post '/article/edit/:id' => sub
{
    my $form = form_article();
    my $id = params->{id};
    my $params_hashref = params;
    $form->process($params_hashref);
    if($form->submitted_and_valid)
    {
        save_article($id, $form);
        redirect dancer_app->prefix . '/article/list';
    }
    template "admin/article", { form => $form->render() }
};

get '/article/delete/:id' => sub
{
    my $id = params->{id};
    my $article_row = schema->resultset('Article')->find($id);
    my %article;
    $article{'id'} = $id;
    $article{'title'} = $article_row->main_title;
    template "admin/delete", { what => "l'articolo", el => \%article, backlink => dancer_app->prefix . '/article' };
};
post '/article/delete/:id' => sub
{
    my $id = params->{id};
    my $article_row = schema->resultset('Article')->find($id);
    $article_row->delete();
    $article_row->contents->delete_all();
    redirect dancer_app->prefix . '/article/list';
};
get '/article/turnon/:id' => sub
{
    my $id = params->{id};
    my $article_row = schema->resultset('Article')->find($id);
    $article_row->published(1);
    $article_row->update();
    redirect dancer_app->prefix . '/article/list';
};
get '/article/turnoff/:id' => sub
{
    my $id = params->{id};
    my $article_row = schema->resultset('Article')->find($id);
    $article_row->published(0);
    $article_row->update();
    redirect dancer_app->prefix . '/article/list';
};

#Categories

get '/category' => sub
{
    redirect dancer_app->prefix . '/category/list';
};

any '/category/list' => sub
{
    #THE TABLE
    my @to_view;
    my @categories = schema->resultset('Category')->all();
    for(@categories)
    {
        my $row = $_;
        my %el;
        $el{'id'} = $row->id;
        $el{'name'} = $row->category;
        push @to_view, \%el;
    }

    #THE FORM
    my $form = HTML::FormFu->new;
    $form->load_config_file( 'forms/admin/category.yml' );
    my $params_hashref = params;
    $form->process($params_hashref);
    if($form->submitted_and_valid)
    {
        my $new_category = schema->resultset('Category')->create({category => $form->param_value('category') });
        my %new_el;
        $new_el{'id'} = $new_category->id;
        $new_el{'name'} = $new_category->category;
        push @to_view, \%new_el;
    }
    template "admin/category", { categories => \@to_view, form => $form };
};

get '/category/delete/:id' => sub
{
    my $id = params->{id};
    my %category;
    my $category_row = schema->resultset('Category')->find($id);
    if($category_row->images->count() > 0 || $category_row->articles->count() > 0)
    {
        my $message = "La categoria " . $category_row->category . " non &egrave; vuota! Non &egrave; possibile cancellarla";    
        my $return = dancer_app->prefix . "/category/list";
        template "admin/message", { message => $message, backlink => $return };
    }
    else
    {
        $category{'id'} = $id;
        $category{'title'} = $category_row->category;
        template "admin/delete", { what => "la categoria", el => \%category, backlink => dancer_app->prefix . '/category' };
    }
};
post '/category/delete/:id' => sub
{
    my $id = params->{id};
    my $category_row = schema->resultset('Category')->find($id);
    $category_row->images->update( { category => undef } );
    $category_row->articles->update( { category => undef } );
    $category_row->delete();
    redirect dancer_app->prefix . '/category/list';
};

get '/category/last/:id' => sub
{
    my $id = params->{id};
    my $max = schema->resultset('Article')->search( { category => $id } )->get_column('display_order')->max();
    return $max+1;
};



##### Helpers #####

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
    my $form = HTML::FormFu->new;
    $form->load_config_file( 'forms/admin/image.yml' );
    $form = add_multilang_fields($form, \@languages, 'forms/admin/image_multilang.yml'); 
    $form->constraint({ name => 'photo', type => 'Required' }) if $action eq 'add';
    my $category = $form->get_element({ name => 'category'});
    $category->options(schema->resultset('Category')->make_select());
    return $form;
}

sub save_image
{
    my $id = shift;
    my $img = shift;
    my $form = shift;
    
    
    my $ref; 
    my $path;
    if($img)
    {
        $ref = '/upload/' . $img->filename;
        $path = 'public' . $ref;
        $img->copy_to($path);
    }
    my $img_row;

    if($id)
    {
        $img_row = schema->resultset('Image')->find($id);
        if($img)
        {
            $img_row->update({ image => $ref, category => $form->param_value('category') });
        }
        else
        {
            $img_row->update({ category => $form->param_value('category') });
        }
        $img_row->descriptions->delete_all();
    }
    else
    {
        $img_row = schema->resultset('Image')->create({ image => $ref, category => $form->param_value('category') });
    }
    for(@languages)
    {
        my $lan = $_;
        $img_row->descriptions->create( { title => $form->param_value('title_' . $lan), description => $form->param_value('description_' . $lan), language => $lan }) if($form->param_value('title_' . $lan) || $form->param_value('description_' . $lan));;
    }
    return $img_row->id;     
}

sub form_article
{
    my $form = HTML::FormFu->new;
    $form->load_config_file( 'forms/admin/article.yml' );
    $form = add_multilang_fields($form, \@languages, 'forms/admin/article_multilang.yml'); 
    $form->constraint({ name => 'title_it', type => 'Required' }); 
    $form->constraint({ name => 'slug_it', type => 'Required' }); 
    $form->constraint({ name => 'text_it', type => 'Required' }); 
    my $image = $form->get_element({ name => 'image'});
    $image->options(schema->resultset('Image')->make_select());
    my $category = $form->get_element({ name => 'category'});
    $category->options(schema->resultset('Category')->make_select());
    return $form;
}

sub save_article
{
    my $id = shift;
    my $form = shift;
    
    my $article_row;
    my $order;
    if($form->param_value('category'))
    {
        $order = $form->param_value('order');
    }
    else
    {
        $order = undef;
    }

    if($id)
    {
        $article_row = schema->resultset('Article')->find($id);
        $article_row->update({ image => $form->param_value('image'), category => $form->param_value('category'), display_order => $order });
        $article_row->contents->delete_all();
    }
    else
    {
        $article_row = schema->resultset('Article')->create({ image => $form->param_value('image'), category => $form->param_value('category'), display_order => $order });
    }
    for(@languages)
    {
        my $lan = $_;
        $article_row->contents->create( { title => $form->param_value('title_' . $lan), text => $form->param_value('text_' . $lan), slug => $form->param_value('slug_' . $lan), language => $lan }) if($form->param_value('title_' . $lan) || $form->param_value('text_' . $lan));
    }
    return $article_row->id;     
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
