package Strehler::Element::User;
        
use Moo;
use Dancer2;
use Dancer2::Plugin::DBIC;
use Authen::Passphrase::BlowfishCrypt;

extends 'Strehler::Element';

#Standard element implementation
sub BUILDARGS {
   my ( $class, @args ) = @_;
   my $id = shift @args; 
   my $user;
   if(! $id)
   {
        $user = undef;
   }
   else
   {
        $user = schema->resultset('User')->find($id);
   }
   return { row => $user };
};
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

#Main title redefined because here it's user
sub main_title
{
    my $self = shift;
    return $self->get_attr('user');
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
    my $already_user = schema->resultset($self->ORMObj())->find({user => $form->param_value('user')});
    return -1 if($already_user && ! $id);
    if($id)
    {
        $user_row = schema->resultset($self->ORMObj())->find($id);
        $user_row->update($user_data);
    }
    else
    {
        $user_row = schema->resultset($self->ORMObj())->create($user_data);
    }
    return $user_row->id;  
}

1;
