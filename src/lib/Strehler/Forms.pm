package Strehler::Forms;

use Cwd 'abs_path';
use HTML::FormFu;

my $module_file_path = __FILE__;
my $root_path = abs_path($module_file_path);
$root_path =~ s/Forms\.pm//;

my $form_path = $root_path . 'forms';



sub form_login
{
    my $form = HTML::FormFu->new;
    $form->auto_error_class('error-msg');
    $form->load_config_file( $form_path . '/admin/login.yml' );
    return $form;    
}

sub form_category
{
    my $form = HTML::FormFu->new;
    $form->auto_error_class('error-msg');
    $form->load_config_file( $form_path . '/admin/category.yml' );
    $form = add_dynamic_fields_for_category($form); 
    my $prev_name = $form->element( { type => 'Hidden', name => 'prev-name'} );
    my $prev_parent = $form->element( { type => 'Hidden', name => 'prev-parent'} );
    my $position = $form->get_element({ name => 'save' });
    $form->insert_before($prev_name, $position);
    $form->insert_before($prev_parent, $position);
    return $form;
}

sub form_category_fast
{
    my $form = HTML::FormFu->new;
    $form->auto_error_class('error-msg');
    $form->load_config_file( $form_path . '/admin/category_fast.yml' );
    return $form;
}

sub form_user
{
    my $action = shift;
    my $form = HTML::FormFu->new;
    $form->auto_error_class('error-msg');
    $form->load_config_file( $form_path . '/admin/user.yml' );
    if($action eq 'add')
    {
        $form->constraint({ name => 'password', type => 'Required' }); 
        $form->constraint({ name => 'password-confirm', type => 'Required' }); 
        $form->constraint({ name => 'user', type => 'Required' }); 
    }
    elsif($action eq 'edit')
    {
        my $user = $form->get_element({ name => 'user' });
        $user->attributes->{readonly} = 'readonly';
        $user->attributes->{disabled} = 'disabled';
    }
    elsif($action eq 'password')
    {
        my $user = $form->get_element({ name => 'user' });
        $user->attributes->{readonly} = 'readonly';
        $user->attributes->{disabled} = 'disabled';
        my $role = $form->get_element({ name => 'role' });
        $role->attributes->{readonly} = 'readonly';
        $role->attributes->{disabled} = 'disabled';
    }
    return $form;
}

sub form_generic
{
    my $conf = shift;
    my $multilang_conf = shift;
    my $action = shift;
    my $has_sub = shift;
    my $languages = shift;
    if(! $conf)
    {
        return undef;
    }

    my $form = HTML::FormFu->new;
    $form->auto_error_class('error-msg');
    $form->load_config_file( $conf );
    my $action_block_conf;
    $action_block_conf->{'type'} = "Hidden";
    $action_block_conf->{'name'} = "strehl-action";
    $form->element($action_block_conf);
    if($multilang_conf)
    {
        $form = add_multilang_fields($form, $languages, $multilang_conf); 
    }
    return $form;
}

sub form_filter
{
    my $conf = shift;
    my $multilang = shift;
    my $selected_language = shift;
    my $languages = shift;
    my @languages_options;
    for my $l (@{$languages})
    {
        push @languages_options, [ $l, $l ];
    }
    my @selected_languages = split( ',', $selected_language );
    my $form = HTML::FormFu->new;
    $form->load_config_file( $conf );
    if($multilang)
    {
        my $languages_block = $form->get_element({ name => 'language-block'});
        my $position = $languages_block->get_elements()->[0];
        $languages_block->insert_after($languages_block->element(
            { label => "Languages:", type => 'Checkboxgroup', name => 'language', options => \@languages_options, default => $selected_language, attributes => { class => 'languages-filter'}}), $position);
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
        my $position = $form->get_elements()->[0]; 
        $form->insert_after($form->element({ type => 'Text', name => 'tags'}), $position);
    }
    elsif($params_hashref->{'tags'})
    { 
        my $position = $form->get_elements()->[0]; 
        $form->insert_after($form->element({ type => 'Text', name => 'tags'}), $position);
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
    my $config = $form_path . '/admin/category_dynamic.yml';
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

1;

=encoding utf8

=head1 NAME

Strehler::Forms - Functions to manage forms

=head1 DESCRIPTION

Functions used as "Forms Factory" by L<Strehler::Admin>, the module where all the CRUD navigation resides.

=head1 FUNCTIONS

Functions that generate forms:

=over 4

=item form_login

=item form_category/form_category_fast

=item form_user

=item form_generic

=item form_filter

=back

tags_for_form is used to manage tags field because it has two different behaviours: as text field and as list of checkboxes.

add_multilang_fields manages multilang forms.

add_dynamic_fields_for_category manipulate category form.



=cut 

