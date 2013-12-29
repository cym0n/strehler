package Strehler::Element::User;
        
use Moo;
use Dancer2;
use Dancer2::Plugin::DBIC;
use Authen::Passphrase::BlowfishCrypt;

extends 'Strehler::Element';


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

sub main_title
{
    my $self = shift;
    return $self->get_attr('user');
}
sub get_basic_data
{
    my $self = shift;
    my %data;
    $data{'id'} = $self->get_attr('id');
    $data{'title'} = $self->main_title;
    return %data;
}
sub get_ext_data
{
    my $self = shift;
    return $self->get_basic_data;
}
#Category accessor used by static methods
sub category_accessor
{
    return undef;
}

sub item_type
{
    return "user";
}

sub ORMObj
{
    return "User";
}
sub multilang_children
{
    return 'no-children';
}

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
    if($id)
    {
        $user_row = schema->resultset('User')->find($id);
        $user_row->update($user_data);
    }
    else
    {
        $user_row = schema->resultset('User')->create($user_data);
    }
    return $user_row->id;  
}

1;
