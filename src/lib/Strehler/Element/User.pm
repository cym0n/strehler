package Strehler::Element::User;
     
use strict;
use Moo;
use Dancer2 0.154000;
use Dancer2::Plugin::DBIC;
use Authen::Passphrase::BlowfishCrypt;

extends 'Strehler::Element';

sub metaclass_data 
{
    my $self = shift;
    my $param = shift;
    my %element_conf = ( item_type => 'user',
                         ORMObj => 'User',
                         category_accessor => '',
                         multilang_children => '' );
    return $element_conf{$param};
}

#Standard configuration overrides
sub exposed
{
    my $self = shift;
    return $self->_property('exposed', 0);
}
sub label
{
    my $self = shift;
    return $self->_property('label', 'Users');
}
sub allowed_role
{
    my $self = shift;
    return $self->_property('allowed_role', 'admin');
}
sub class
{
    return __PACKAGE__;
}


#Main title redefined because here it's user
sub main_title
{
    my $self = shift;
    return $self->get_attr('user');
}

sub fields_list
{
    my $self = shift;
    my @fields = ( { 'id' => 'id',
                     'label' => 'ID',
                     'ordinable' => 1 },
                   { 'id' => 'user',
                     'label' => 'Username',
                     'ordinable' => 1 },
               );
    return \@fields;
    
}

#Because of password management we need to override form management methods
sub get_form_data
{
    my $self = shift;
    my $user_row = $self->row;
    my $data;
    $data->{'user'} = $self->get_attr('user');
    $data->{'role'} = $self->get_attr('role');
    return $data;
}

sub save_form
{
    my $self = shift;
    my $id = shift;
    my $form = shift;
    
    my $user_row;
    my $clean_password = $form->param_value('password');
    my $user_data = $self->generate_crypted_password($clean_password);
    $user_data->{ user } = $form->param_value('user');
    $user_data->{ role } = $form->param_value('role');
    my $already_user = $self->get_schema()->resultset($self->ORMObj())->find({user => $form->param_value('user')});
    return -1 if($already_user && ! $id);
    if($id)
    {
        $user_row = $self->get_schema()->resultset($self->ORMObj())->find($id);
        $user_row->update($user_data);
    }
    else
    {
        $user_row = $self->get_schema()->resultset($self->ORMObj())->create($user_data);
    }
    return $user_row->id;  
}

sub save_password
{
    my $self = shift;
    my $id = shift;
    my $form = shift;

    my $clean_password = $form->param_value('password');
    my $user_data = $self->generate_crypted_password($clean_password);
    my $user_row = $self->get_schema()->resultset($self->ORMObj())->find($id);
    return -1 if( ! $user_row );
    $user_row->update($user_data);
    return $user_row->id;
}

sub generate_crypted_password
{
    my $self = shift;
    my $clean_password = shift;
    my $ppr = Authen::Passphrase::BlowfishCrypt->new(
                cost => 8, salt_random => 1,
                passphrase => $clean_password);
    return { password_hash => $ppr->hash_base64, password_salt => $ppr->salt_base64 };
}

sub valid_login
{
    my $self = shift;
    my $user = shift;
    my $password = shift;
    my $rs = $self->get_schema()->resultset($self->ORMObj())->find({'user' => $user});
    if($rs && $rs->user eq $user)
    {
        my $ppr = Authen::Passphrase::BlowfishCrypt->new(
                  cost => 8, salt_base64 => $rs->password_salt,
                  hash_base64 => $rs->password_hash);
        if($ppr->match($password))
        {
            return Strehler::Element::User->new($rs->id);
        }
    }
    return undef;
}

sub get_from_username
{
    my $self = shift;
    my $username = shift;
    my $rs = $self->get_schema()->resultset($self->ORMObj())->find({'user' => $username});
    if($rs && $rs->user eq $username)
    {
        return $self->new($rs->id);
    }
    else
    {
        return undef;
    }
}

sub install
{
    return "Standard entity. No installation is needed.";
}

sub delete
{
    my $self = shift;
    if($self->get_attr("user") eq "admin")
    {
        return 2;
    }
    return SUPER->delete();
}

sub error_message
{
    my $self = shift;
    my $action = shift;
    my $code = shift;
    if($action eq 'delete' && $code == 2)
    {
        return "Admin user cannot be deleted";
    }
    else
    {
        return SUPER->error_message($action, $code);
    }
}



=encoding utf8

=head1 NAME

Strehler::Element::User - Strehler Entity for users

=head1 DESCRIPTION

A little entity used to manage users.

It keeps also password saving logic. Password is saved using L<Authen::Passphrase::BlowfishCrypt>

=cut


1;
