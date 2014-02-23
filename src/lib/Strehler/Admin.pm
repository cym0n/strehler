package Strehler::Admin;

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
use Strehler::Element::Log;
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
    template "admin/login", { form => $form->render(), message => $message }, { layout => 'light-admin' }
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
        my $id = Strehler::Element::Image->save_form(undef, $img, $form);
        Strehler::Element::Log->write(session->read('user'), 'add', 'image', $id);
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
        Strehler::Element::Image->save_form($id, $img, $form);
        Strehler::Element::Log->write(session->read('user'), 'edit', 'image', $id);
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
        my $id = Strehler::Element::Article->save_form(undef, $form);
        Strehler::Element::Log->write(session->read('user'), 'add', 'article', $id);
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
        Strehler::Element::Article->save_form($id, $form);
        Strehler::Element::Log->write(session->read('user'), 'edit', 'article', $id);
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
    my $message = "";
    if($form->submitted_and_valid)
    {
        my $id = Strehler::Element::User->save_form(undef, $form);
        if($id == -1)
        {
            $message = "Username already in use";
        }
        else
        {
            Strehler::Element::Log->write(session->read('user'), 'add', 'user', $id);
            redirect dancer_app->prefix . '/user/list';
        }
    }
    $form = bootstrap_divider($form);
    template "admin/user", { form => $form->render(), message => $message }
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
    my $message;
    if($form->submitted_and_valid)
    {
        my $return_id = Strehler::Element::User->save_form($id, $form);
        if($return_id == -1)
        {
            $message = "Username already in use";
        }
        else
        {
            Strehler::Element::Log->write(session->read('user'), 'edit', 'user', $id);
            redirect dancer_app->prefix . '/user/list';
        }
    }
    template "admin/user", { form => $form->render(), message => $message }
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
    my $to_view = Strehler::Meta::Category->get_list();

    #THE FORM
    my $form = HTML::FormFu->new;
    my @entities = Strehler::Helpers::get_categorized_entities();
    $form->load_config_file( 'forms/admin/category_fast.yml' );
    my $parent = $form->get_element({ name => 'parent'});
    $parent->options(Strehler::Meta::Category->make_select());
    my $params_hashref = params;
    $form->process($params_hashref);
    if($form->submitted_and_valid)
    {
        my $id = Strehler::Meta::Category->save_form(undef, $form, \@entities);
        Strehler::Element::Log->write(session->read('user'), 'add', 'category', $id);
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
    my @entities = Strehler::Helpers::get_categorized_entities();
    $form->process($params_hashref);
    if($form->submitted_and_valid)
    {
        my $id = Strehler::Meta::Category->save_form(undef, $form, \@entities);
        Strehler::Element::Log->write(session->read('user'), 'add', 'category', $id);
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
    my @entities = Strehler::Helpers::get_categorized_entities();
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
    my @entities = Strehler::Helpers::get_categorized_entities();
    $form->process($params_hashref);
    if($form->submitted_and_valid)
    {
        Strehler::Meta::Category->save_form($id, $form, \@entities);
        Strehler::Element::Log->write(session->read('user'), 'edit', 'category', $id);
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
        my $message = "Category " . $category->get_attr('category') . " is not empty! Deletion is impossible.";    
        my $return = dancer_app->prefix . "/category/list";
        template "admin/message", { message => $message, backlink => $return };
    }
    elsif($category->is_parent())
    {
        my $message = "Category " . $category->get_attr('category') . " has subcategories! Deletion is impossible.";    
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
    Strehler::Element::Log->write(session->read('user'), 'delete', 'category', $id);
    redirect dancer_app->prefix . '/category/list';
};

ajax '/category/select/:id' => sub
{
    my $id = params->{id};
    my $data = Strehler::Meta::Category->make_select($id);
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
    my $data = Strehler::Meta::Category->make_select(undef);
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
    my $entity = params->{entity};
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
    my $entity = params->{entity};
    my %entity_data = Strehler::Helpers::get_entity_data($entity);
    if(! $entity_data{'auto'})
    {
        return pass;
    }
    if (! check_role($entity))
    {
        send_error("Access denied", 403);
        return;
    }

    my $custom_list_view = $entity_data{'custom_list_view'} || 'admin/generic_list';
    
    my $page = exists params->{'page'} ? params->{'page'} : session $entity . '-page';
    my $cat_param = exists params->{'cat'} ? params->{'cat'} : session $entity . '-cat-filter';
    my $wanted_cat = undef;
    if(exists params->{'catname'})
    {
        $wanted_cat = Strehler::Meta::Category->explode_name(params->{'catname'});
        $cat_param = $wanted_cat->get_attr('id');
    }
    else
    {
        if($cat_param)
        {
            $wanted_cat = Strehler::Meta::Category->new($cat_param);
        }
    }
    my $cat = undef;
    my $subcat = undef;
    if($wanted_cat)
    {
        if($wanted_cat->row->parent)
        {
            $cat = $wanted_cat->row->parent->id;
            $subcat = $wanted_cat->row->id;
        }
        else
        {
            $cat = $wanted_cat->row->id;
        }
    }
    $page ||= 1;
    my $entries_per_page = 20;
    my $class = $entity_data{'class'};
    eval "require $class";
    my $elements = $class->get_list({ page => $page, entries_per_page => $entries_per_page, category_id => $cat_param});
    session $entity . '-page' => $page;
    session $entity . '-cat-filter' => $cat_param;
    template $custom_list_view, { (entity => $entity, elements => $elements->{'to_view'}, page => $page, cat_filter => $cat, subcat_filter => $subcat, last_page => $elements->{'last_page'}), %entity_data };
};
get '/:entity/turnon/:id' => sub
{
    my $entity = params->{entity};
    my %entity_data = Strehler::Helpers::get_entity_data($entity);
    if(! $entity_data{'auto'})
    {
        return pass;
    }
    if(! $entity_data{'publishable'})
    {
        return pass;
    }
    if (! check_role($entity))
    {
        send_error("Access denied", 403);
        return;
    }
    my $class = $entity_data{'class'};
    my $id = params->{id};
    eval "require $class";
    my $obj = $class->new($id);
    $obj->publish();
    Strehler::Element::Log->write(session->read('user'), 'publish', $entity, $id);
    redirect dancer_app->prefix . '/'. $entity . '/list';
};
get '/:entity/turnoff/:id' => sub
{
    my $entity = params->{entity};
    my %entity_data = Strehler::Helpers::get_entity_data($entity);
    if(! $entity_data{'auto'})
    {
        return pass;
    }
    if(! $entity_data{'publishable'})
    {
        return pass;
    }
    if (! check_role($entity))
    {
        send_error("Access denied", 403);
        return;
    }
    my $class = $entity_data{'class'};
    my $id = params->{id};
    eval "require $class";
    my $obj = $class->new($id);
    $obj->unpublish();
    Strehler::Element::Log->write(session->read('user'), 'unpublish', $entity, $id);
    redirect dancer_app->prefix . '/'. $entity . '/list';
};
get '/:entity/delete/:id' => sub
{
    my $entity = params->{entity};
    if(! Strehler::Helpers::get_entity_attr($entity, 'auto'))
    {
        return pass;
    }
    if (! check_role($entity))
    {
        send_error("Access denied", 403);
        return;
    }
    if (! Strehler::Helpers::get_entity_attr($entity, 'deletable'))
    {
        send_error("Access denied", 403);
        return;
    }
    my $id = params->{id};
    my $class = Strehler::Helpers::get_entity_attr($entity, 'class');
    my $label = Strehler::Helpers::get_entity_attr($entity, 'label');
    eval "require $class";
    my $obj = $class->new($id);
    my %el = $obj->get_basic_data();
    template "admin/delete", { what => $label, el => \%el, backlink => dancer_app->prefix . '/' . $entity };
};
post '/:entity/delete/:id' => sub
{
    my $entity = params->{entity};
    if(! Strehler::Helpers::get_entity_attr($entity, 'auto'))
    {
        return pass;
    }
    if (! check_role($entity))
    {
        send_error("Access denied", 403);
        return;
    }
    if (! Strehler::Helpers::get_entity_attr($entity, 'deletable'))
    {
        send_error("Access denied", 403);
        return;
    }
    my $id = params->{id};
    my $class = Strehler::Helpers::get_entity_attr($entity, 'class');
    eval "require $class";
    my $obj = $class->new($id);
    $obj->delete();
    Strehler::Element::Log->write(session->read('user'), 'delete', $entity, $id);
    redirect dancer_app->prefix . '/' . $entity . '/list';
};
ajax '/:entity/tagform/:id?' => sub
{
    my $entity = params->{entity};
    if(! Strehler::Helpers::get_entity_attr($entity, 'auto'))
    {
        return pass;
    }
    if(! Strehler::Helpers::get_entity_attr($entity, 'categorized'))
    {
        return pass;
    }
    my $class = Strehler::Helpers::get_entity_attr($entity, 'class');
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
            template 'admin/open_tags', { tags => $obj->get_tags() };
        }
    }
    else
    {
           template 'admin/open_tags';
    }
};
ajax '/:entity/lastchapter/:id' => sub
{
    my $entity = params->{entity};
    my $id = params->{id};
    my %entity_data = Strehler::Helpers::get_entity_data($entity);
    if(! $entity_data{'auto'})
    {
        return pass;
    }
    if(! $entity_data{'ordered'})
    {
        return pass;
    }
    my $class = Strehler::Helpers::get_entity_attr($entity, 'class');
    eval "require $class";
    return $class->max_category_order($id) +1;
};

any '/:entity/add' => sub
{
    my $entity = params->{entity};
    if(! Strehler::Helpers::get_entity_attr($entity, 'auto'))
    {
        return pass;
    }
    if(! Strehler::Helpers::get_entity_attr($entity, 'creatable'))
    {
        return pass;
    }
    my $class = Strehler::Helpers::get_entity_attr($entity, 'class'),
    my $label = Strehler::Helpers::get_entity_attr($entity, 'label'),
    my $form = form_generic(Strehler::Helpers::get_entity_attr($entity, 'form'), Strehler::Helpers::get_entity_attr($entity, 'multilang_form'), 'add'); 
    my $params_hashref = params;
    $form = Strehler::Admin::tags_for_form($form, $params_hashref);
    if(! $form)
    {
        return pass;
    }
    $form->process($params_hashref);
    if($form->submitted_and_valid)
    {
        eval "require $class";
        my $id = $class->save_form(undef, $form);
        Strehler::Element::Log->write(session->read('user'), 'add', $entity, $id);
        redirect dancer_app->prefix . '/' . $entity . '/list';
    }
    my $fake_tags = $form->get_element({ name => 'tags'});
    Strehler::Admin::bootstrap_divider($form);
    $form->remove_element($fake_tags) if($fake_tags);
    template "admin/generic_add", { entity => $entity, label => $label, form => $form->render() }
};
get '/:entity/edit/:id' => sub {
    my $id = params->{id};
    my $entity = params->{entity};
    if(! Strehler::Helpers::get_entity_attr($entity, 'auto'))
    {
        return pass;
    }
    if(! Strehler::Helpers::get_entity_attr($entity, 'updatable'))
    {
        return pass;
    }
    my $class = Strehler::Helpers::get_entity_attr($entity, 'class');
    my $label = Strehler::Helpers::get_entity_attr($entity, 'label');
    eval "require $class";
    my $el = $class->new($id);
    my $form_data = $el->get_form_data();
    my $form = form_generic(Strehler::Helpers::get_entity_attr($entity, 'form'), Strehler::Helpers::get_entity_attr($entity, 'multilang_form'), 'edit', $form_data->{'category'});
    if(! $form)
    {
        return pass;
    }
    $form->default_values($form_data);
    $form = Strehler::Admin::bootstrap_divider($form);
    template "admin/generic_add", {  entity => $entity, label => $label, id => $id, form => $form->render() }
};
post '/:entity/edit/:id' => sub
{
    my $id = params->{id};
    my $entity = params->{entity};
    if(! Strehler::Helpers::get_entity_attr($entity, 'auto'))
    {
        return pass;
    }
    if(! Strehler::Helpers::get_entity_attr($entity, 'updatable'))
    {
        return pass;
    }
    my $class = Strehler::Helpers::get_entity_attr($entity, 'class');
    my $label = Strehler::Helpers::get_entity_attr($entity, 'label');
    my $form = form_generic(Strehler::Helpers::get_entity_attr($entity, 'form'), Strehler::Helpers::get_entity_attr($entity, 'multilang_form'), 'edit');
    if(! $form)
    {
        return pass;
    }
    my $params_hashref = params;
    $form = Strehler::Admin::tags_for_form($form, $params_hashref);
    $form->process($params_hashref);
    if($form->submitted_and_valid)
    {
        eval "require $class";
        $class->save_form($id, $form);
        Strehler::Element::Log->write(session->read('user'), 'edit', $entity, $id);
        redirect dancer_app->prefix . '/' . $entity . '/list';
    }
    template "admin/generic_add", { entity => $entity, label => $label, id => $id, form => $form->render() }
};

##### Helpers #####
# They only manipulate forms rendering and manage login

sub login_valid
{
    my $user = shift;
    my $password = shift;
    my $rs = schema->resultset('User')->find({'user' => $user});
    if($rs && $rs->user eq $user)
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
    $category->options(Strehler::Meta::Category->make_select());
    my $subcategory = $form->get_element({ name => 'subcategory'});
    $subcategory->options(Strehler::Meta::Category->make_select($has_sub));
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
    my $image = $form->get_element({ name => 'image'});
    $image->options(Strehler::Element::Image->make_select());
    my $category = $form->get_element({ name => 'category'});
    $category->options(Strehler::Meta::Category->make_select());
    my $subcategory = $form->get_element({ name => 'subcategory'});
    $subcategory->options(Strehler::Meta::Category->make_select($has_sub));
    return $form;
}

sub form_category
{
    my $form = HTML::FormFu->new;
    $form->load_config_file( 'forms/admin/category.yml' );
    my $category = $form->get_element({ name => 'parent'});
    $category->options(Strehler::Meta::Category->make_select());
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

sub form_generic
{
    my $conf = shift;
    my $multilang_conf = shift;
    my $action = shift;
    my $has_sub = shift;
    if(! $conf)
    {
        return undef;
    }

    my $form = HTML::FormFu->new;
    $form->load_config_file( $conf );
    if($multilang_conf)
    {
        $form = add_multilang_fields($form, \@languages, $multilang_conf); 
    }
    my $category = $form->get_element({ name => 'category'});
    if($category)
    {
       $category->options(Strehler::Meta::Category->make_select());
       my $subcategory = $form->get_element({ name => 'subcategory'});
       if($subcategory)
       {
           $subcategory->options(Strehler::Meta::Category->make_select($has_sub));
       }
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
    for(Strehler::Helpers::get_categorized_entities())
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

sub check_role
{
    if(! config->{Strehler}->{admin_secured})
    {
        return 1;
    }
    my $entity = shift;
    my %entity_data = Strehler::Helpers::get_entity_data($entity);
    if($entity_data{'role'})
    {
        if(session->read('role') eq $entity_data{'role'})
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
