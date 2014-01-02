# Script to generate the SQL insert for the admin user 
# on a fresh Strehler installation

# It will create the user named admin with the wanted password

use v5.10;

use Authen::Passphrase::BlowfishCrypt;
use Term::ReadKey;

my $USERS_TABLE = 'USERS';
my $USER = 'admin';
my $ROLE = 'admin';



ReadMode(2, STDIN);
say "Enter password for admin:";
my $password = <STDIN>;
say "Re-type password:";
my $password_confirm = <STDIN>;
ReadMode(0);
if(! ($password eq $password_confirm))
{
    say "Password inputs don't match!";
    exit(0);
}
chomp $password;
my $ppr = Authen::Passphrase::BlowfishCrypt->new(
                cost => 8, salt_random => 1,
                passphrase => $password);
my $hash = $ppr->hash_base64;
my $salt = $ppr->salt_base64;

my $output_query = "INSERT INTO $USERS_TABLE (USER, PASSWORD_HASH, PASSWORD_SALT, ROLE) VALUES ('$USER', '$hash', '$salt', '$ROLE');";

say "INSERT QUERY is:";
say $output_query;






