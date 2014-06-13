package Strehler::Element::User;
        
use Moo;
use Dancer2 0.11;
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
    return config->{'Strehler'}->{'extra_menu'}->{'user'}->{exposed} || 0;
}
sub label
{
    return config->{'Strehler'}->{'extra_menu'}->{'user'}->{label} || "Users";
}
sub allowed_role
{
    if(config->{'Strehler'}->{'extra_menu'}->{'log'}->{allowed_role})
    {
        return config->{'Strehler'}->{'extra_menu'}->{'log'}->{allowed_role};
    }
    elsif(config->{'Strehler'}->{'extra_menu'}->{'log'}->{role}) 
    {
        #For retrocompatibility
        return config->{'Strehler'}->{'extra_menu'}->{'log'}->{role};
    }
    else
    {
        return 'admin';
    }
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
    my $ppr = Authen::Passphrase::BlowfishCrypt->new(
                cost => 8, salt_random => 1,
                passphrase => $clean_password);
    my $user_data ={ user => $form->param_value('user'), password_hash => $ppr->hash_base64, password_salt => $ppr->salt_base64, role => $form->param_value('role') };
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

=encoding utf8

=head1 NAME

Strehler::Element::User - Strehler Entity for users

=head1 DESCRIPTION

A little entity used to manage users.

It keeps also password saving logic. Password is saved using L<Authen::Passphrase::BlowfishCrypt>

=cut


1;
