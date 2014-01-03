package Strehler::Admin;

use Digest::MD5 "md5_hex";
use Dancer2;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::Ajax;
use Dancer2::Plugin::Strehler;
use HTML::FormFu;
use HTML::FormFu::Element::Block;
use Authen::Passphrase::BlowfishCrypt;
use Strehler::Helpers;
use Strehler::Meta::Tag;
use Strehler::Element::Image;
use Strehler::Element::Article;
use Strehler::Element::User;
use Strehler::Meta::Category;


my @languages = @{config->{Strehler}->{languages}};

##### Homepage #####

get '/' => sub {
    my %navbar;
    $navbar{'home'} = "active";
    template "admin/index", { navbar => \%navbar};
};

##### Login/Logout #####

any '/login' => sub {
    my $form = HTML::FormFu->new;
    $form->load_config_file( 'forms/admin/login.yml' );
    my $params_hashref = params;
    $form->process($params_hashref);
    my $message;
    if($form->submitted_and_valid)
    {
        my $role = login_valid($params_hashref->{'user'}, $params_hashref->{'password'});
        if($role)
        {
            session 'user' => $params_hashref->{'user'};
            session 'role' => $role;
            if( session 'redir_url' )
            {
                my $redir = redirect(session 'redir_url');
                return $redir;
            }
            else
            {
                my $redir = redirect(dancer_app->prefix . '/');
                return $redir;
            }
        }
        else
        {
            $message = "Authentication failed!";
        }
    }
    template "admin/login", { form => $form->render(), message => $message, layout => 'admin' }
};

get '/logout' => sub
{
    session 'user' => undef;
    session 'role' => undef;
    my $redir = redirect(dancer_app->prefix . '/');
    return $redir;
};

##### Images #####

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

##### Articles #####

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

#Users

any '/user/add' => sub
{
    if (! check_role('user'))
    {
        send_error("Access denied", 403);
        return;
    }
    my $form = form_user('add');
    my $params_hashref = params;
    $form->process($params_hashref);
    if($form->submitted_and_valid)
    {
        my $id = Strehler::Element::User->save_form(undef, $form);
        redirect dancer_app->prefix . '/user/list';
    }
    $form = bootstrap_divider($form);
    template "admin/user", { form => $form->render() }
};

get '/user/edit/:id' => sub {
    if (! check_role('user'))
    {
        send_error("Access denied", 403);
        return;
    }
    my $id = params->{id};
    my $user = Strehler::Element::User->new($id);
    my $form_data = $user->get_form_data();
    my $form = form_user('edit');
    $form->default_values($form_data);
    template "admin/user", { form => $form->render() }
};

post '/user/edit/:id' => sub
{
    if (! check_role('user'))
    {
        send_error("Access denied", 403);
        return;
    }
    my $form = form_user('edit');
    my $id = params->{id};
    my $params_hashref = params;
    $form->process($params_hashref);
    if($form->submitted_and_valid)
    {
        Strehler::Element::User->save_form($id, $form);
        redirect dancer_app->prefix . '/user/list';
    }
    template "admin/user", { form => $form->render() }
};

#Categories

get '/category' => sub
{
    if (! check_role('category'))
    {
        send_error("Access denied", 403);
        return;
    }
    redirect dancer_app->prefix . '/category/list';
};

any '/category/list' => sub
{
    if (! check_role('category'))
    {
        send_error("Access denied", 403);
        return;
    }
    #THE TABLE
    my $to_view = Strehler::Meta::Category::get_list();

    #THE FORM
    my $form = HTML::FormFu->new;
    my @entities = get_categorized_entities();
    $form->load_config_file( 'forms/admin/category_fast.yml' );
    my $parent = $form->get_element({ name => 'parent'});
    $parent->options(Strehler::Meta::Category::make_select());
    my $params_hashref = params;
    $form->process($params_hashref);
    if($form->submitted_and_valid)
    {
        my $new_category = Strehler::Meta::Category::save_form(undef, $form, \@entities);
        redirect dancer_app->prefix . '/category/list';
    }
    template "admin/category_list", { categories => $to_view, form => $form };
};

any '/category/add' => sub
{
    if (! check_role('category'))
    {
        send_error("Access denied", 403);
        return;
    }
    my $form = form_category();
    my $params_hashref = params;
    my @entities = get_categorized_entities();
    $form->process($params_hashref);
    if($form->submitted_and_valid)
    {
        Strehler::Meta::Category::save_form(undef, $form, \@entities);
        redirect dancer_app->prefix . '/category/list'; 
    }
    $form = bootstrap_divider($form);
    template "admin/category", { form => $form->render() }
};
get '/category/edit/:id' => sub {
    if (! check_role('category'))
    {
        send_error("Access denied", 403);
        return;
    }
    my $id = params->{id};
    my $category = Strehler::Meta::Category->new($id);
    my @entities = get_categorized_entities();
    my $form_data = $category->get_form_data(\@entities);
    my $form = form_category();
    $form->default_values($form_data);
    $form = bootstrap_divider($form);
    template "admin/category", { form => $form->render() }
};
post '/category/edit/:id' => sub
{
    if (! check_role('category'))
    {
        send_error("Access denied", 403);
        return;
    }
    my $form = form_category();
    my $id = params->{id};
    my $params_hashref = params;
    my @entities = get_categorized_entities();
    $form->process($params_hashref);
    if($form->submitted_and_valid)
    {
        Strehler::Meta::Category::save_form($id, $form, \@entities);
        redirect dancer_app->prefix . '/category/list';
    }
    template "admin/category", { form => $form->render() }
};

get '/category/delete/:id' => sub
{
    if (! check_role('category'))
    {
        send_error("Access denied", 403);
        return;
    }
    my $id = params->{id};
    my $category = Strehler::Meta::Category->new($id);
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
    if (! check_role('category'))
    {
        send_error("Access denied", 403);
        return;
    }
    my $id = params->{id};
    my $category = Strehler::Meta::Category->new($id);
    $category->delete();
    redirect dancer_app->prefix . '/category/list';
};

ajax '/category/last/:id' => sub
{
    my $id = params->{id};
    my $category = Strehler::Meta::Category->new($id);
    return $category->max_article_order() + 1;
};
ajax '/category/select/:id' => sub
{
    my $id = params->{id};
    my $data = Strehler::Meta::Category::make_select($id);
    if($data->[1])
    {
        template 'admin/category_select', { categories => $data }, { layout => undef };
    }
    else
    {
        return 0;
    }
};
ajax '/category/select' => sub
{
    my $data = Strehler::Meta::Category::make_select(undef);
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
        my @tags = Strehler::Meta::Tag->get_configured_tags_for_template(params->{id}, params->{type});
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

get '/:entity' => sub
{
    my ($entity, $class, $categorized, $publishable, $custom_list_view) = get_entity_data(params->{entity});
    if($entity)
    {
        if (! check_role($entity))
        {
            send_error("Access denied", 403);
            return;
        }
        redirect dancer_app->prefix . '/' . $entity . '/list';
    }
    else
    {
        return pass;
    }
};

any '/:entity/list' => sub
{
    my ($entity, $class, $categorized, $publishable, $custom_list_view) = get_entity_data(params->{entity});
    if(! $entity)
    {
        return pass;
    }
    if (! check_role($entity))
    {
        send_error("Access denied", 403);
        return;
    }
    $custom_list_view ||= 'admin/generic_list';
    
    my $page = exists params->{'page'} ? params->{'page'} : session $entity . '-page';
    my $cat_param = exists params->{'cat'} ? params->{'cat'} : session $entity . '-cat-filter';
    if(exists params->{'catname'})
    {
        my $wanted_cat = Strehler::Meta::Category::explode_name(params->{'catname'});
        $cat_param = $wanted_cat->get_attr('id');
    }
    $page ||= 1;
    my $cat = undef;
    my $subcat = undef;
    ($cat, $subcat) = Strehler::Meta::Category::explode_tree($cat_param);
    my $entries_per_page = 20;
    eval "require $class";
    my $elements = $class->get_list({ page => $page, entries_per_page => $entries_per_page, category_id => $cat_param});
    session $entity . '-page' => $page;
    session $entity . '-cat-filter' => $cat_param;
    template $custom_list_view, { entity => $entity, elements => $elements->{'to_view'}, page => $page, cat_filter => $cat, subcat_filter => $subcat, last_page => $elements->{'last_page'}, categorized => $categorized, publishable => $publishable };
};
get '/:entity/turnon/:id' => sub
{
    my ($entity, $class, $categorized, $publishable, $custom_list_view) = get_entity_data(params->{entity});
    if(! $entity)
    {
        return pass;
    }
    if(! $publishable)
    {
        return pass;
    }
    if (! check_role($entity))
    {
        send_error("Access denied", 403);
        return;
    }
    my $id = params->{id};
    eval "require $class";
    my $obj = $class->new($id);
    $obj->publish();
    redirect dancer_app->prefix . '/'. $entity . '/list';
};
get '/:entity/turnoff/:id' => sub
{
    my ($entity, $class, $categorized, $publishable, $custom_list_view) = get_entity_data(params->{entity});
    if(! $entity)
    {
        return pass;
    }
    if(! $publishable)
    {
        return pass;
    }
    if (! check_role($entity))
    {
        send_error("Access denied", 403);
        return;
    }
    my $id = params->{id};
    eval "require $class";
    my $obj = $class->new($id);
    $obj->unpublish();
    redirect dancer_app->prefix . '/'. $entity . '/list';
};
get '/:entity/delete/:id' => sub
{
    my ($entity, $class, $categorized, $publishable, $custom_list_view) = get_entity_data(params->{entity});
    if(! $entity)
    {
        return pass;
    }
    if (! check_role($entity))
    {
        send_error("Access denied", 403);
        return;
    }
    my $id = params->{id};
    eval "require $class";
    my $obj = $class->new($id);
    my %el = $obj->get_basic_data();
    template "admin/delete", { what => $entity, el => \%el, backlink => dancer_app->prefix . '/' . $entity };
};
post '/:entity/delete/:id' => sub
{
    my ($entity, $class, $categorized, $publishable, $custom_list_view) = get_entity_data(params->{entity});
    if(! $entity)
    {
        return pass;
    }
    if (! check_role($entity))
    {
        send_error("Access denied", 403);
        return;
    }
    my $id = params->{id};
    eval "require $class";
    my $obj = $class->new($id);
    $obj->delete();
    redirect dancer_app->prefix . '/' . $entity . '/list';
};
ajax '/:entity/tagform/:id?' => sub
{
    my ($entity, $class, $categorized, $publishable, $custom_list_view) = get_entity_data(params->{entity});
    if(! $entity)
    {
        return pass;
    }
    if(! $categorized)
    {
        return pass;
    }
    if(params->{id})
    {
        eval "require $class";
        my $obj = $class->new(params->{id});
        my @category_tags = Strehler::Meta::Tag->get_configured_tags_for_template($obj->get_attr('category'), $entity);
        my @tags = split(',', $obj->get_tags());
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


##### Helpers #####
# They only manipulate forms rendering and manage login

sub login_valid
{
    my $user = shift;
    my $password = shift;
    my $rs = schema->resultset('User')->find({'user' => $user});
    if($rs)
    {
        my $ppr = Authen::Passphrase::BlowfishCrypt->new(
                  cost => 8, salt_base64 => $rs->password_salt,
                  hash_base64 => $rs->password_hash);
        if($ppr->match($password))
        {
            return $rs->role;
        }
    }
    return undef;
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
    $category->options(Strehler::Meta::Category::make_select());
    my $subcategory = $form->get_element({ name => 'subcategory'});
    $subcategory->options(Strehler::Meta::Category::make_select($has_sub));
    return $form;
}

sub form_article
{
    my $has_sub = shift;
    my $form = HTML::FormFu->new;
    $form->load_config_file( 'forms/admin/article.yml' );
    $form = add_multilang_fields($form, \@languages, 'forms/admin/article_multilang.yml'); 
    my $default_language = config->{Strehler}->{default_language};
    $form->constraint({ name => 'title_' . $default_language, type => 'Required' }); 
    #$form->constraint({ name => 'text_' . $default_language, type => 'Required' }); 
    my $image = $form->get_element({ name => 'image'});
    $image->options(Strehler::Element::Image::make_select());
    my $category = $form->get_element({ name => 'category'});
    $category->options(Strehler::Meta::Category::make_select());
    my $subcategory = $form->get_element({ name => 'subcategory'});
    $subcategory->options(Strehler::Meta::Category::make_select($has_sub));
    return $form;
}

sub form_category
{
    my $form = HTML::FormFu->new;
    $form->load_config_file( 'forms/admin/category.yml' );
    my $category = $form->get_element({ name => 'parent'});
    $category->options(Strehler::Meta::Category::make_select());
    $form = add_dynamic_fields_for_category($form); 
    return $form;
}

sub form_user
{
    my $action = shift;
    my $form = HTML::FormFu->new;
    $form->load_config_file( 'forms/admin/user.yml' );
    if($action eq 'add')
    {
        $form->constraint({ name => 'password', type => 'Required' }); 
        $form->constraint({ name => 'password-confirm', type => 'Required' }); 
    }
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

sub add_dynamic_fields_for_category
{
    my $form = shift;
    my $config = 'forms/admin/category_dynamic.yml';
    my $position = $form->get_element({ name => 'save' });
    for(get_categorized_entities())
    {
        my $ent = $_;
        my $form_dyna = HTML::FormFu->new;
        my $fieldset = HTML::FormFu::Element::Fieldset->new;
        $fieldset->element( { name => 'placeholder', type => 'Blank' } );
        my $f_position = $fieldset->get_element( { name => 'placeholder' } );
        $form_dyna->load_config_file($config);
        for(@{$form_dyna->get_elements()})
        {
            my $el = $_;
            if(ref($el) eq "HTML::FormFu::Element::Block")
            {
                $el->content("Per " . $ent);
                $el->name($el->name() . '-' . $ent);
                $fieldset->insert_before($el->clone(), $f_position);
            }
            else
            {
                $el->name($el->name() . '-' . $ent);
                $fieldset->insert_before($el->clone(), $f_position);
            }
        }
        $form->insert_before($fieldset->clone(), $position);
    }
    return $form;
}
sub get_categorized_entities
{
    my @entities = ('article', 'image'); #standard entities for Strehler
    my $extra = config->{'Strehler'}->{'extra_menu'};
    for(keys %{$extra})
    {
        if(config->{'Strehler'}->{'extra_menu'}->{$_}->{'categorized'})
        {
            push @entities, $_;
        }
    }
    return @entities;
}

sub get_entity_data
{
    my $entity = shift;
    my $class = undef;
    my $categorized = undef;
    my $publishable = undef;
    my $custom_list_view = undef;
    if($entity eq 'article')
    {
        $class = 'Strehler::Element::Article';
        $categorized = 1;
        $publishable = 1;
        $custom_list_view = 'admin/article_list';
    }
    elsif($entity eq 'image')
    {
        $class = 'Strehler::Element::Image';
        $categorized = 1;
        $publishable = 1;
        $custom_list_view = 'admin/image_list';
    }
    elsif($entity eq 'user')
    {
        $class = 'Strehler::Element::User';
        $categorized = 0;
        $publishable = 0;
#        $custom_list_view = 'admin/image_list';
    }
  
    elsif(config->{'Strehler'}->{'extra_menu'}->{$entity})
    {
        if(config->{'Strehler'}->{'extra_menu'}->{$entity}->{auto})
        {
            $class = config->{'Strehler'}->{'extra_menu'}->{$entity}->{class};
            $categorized = config->{'Strehler'}->{'extra_menu'}->{$entity}->{categorized};
            $publishable = config->{'Strehler'}->{'extra_menu'}->{$entity}->{publishable};
            $custom_list_view = config->{'Strehler'}->{'extra_menu'}->{$entity}->{custom_list_view}; 
        }
        else
        {
            $entity = undef;
        }
    }
    else
    {
        $entity = undef;
    }
    return ($entity, $class, $categorized, $publishable, $custom_list_view);
}
sub check_role
{
    my $entity = shift;
    if($entity eq 'user' || $entity eq 'category')
    {
        if(session->read('role') && session->read('role') eq 'admin')
        {
            return 1;
        }
        else
        {
            return 0;
        }
    }
    else
    {
        return 1;
    }
}



1;
