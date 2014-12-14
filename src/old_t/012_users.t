use strict;
use warnings;

use Test::More;
use Test::TCP;
use LWP::UserAgent;
use FindBin;

$ENV{DANCER_CONFDIR} = 't/testapp';
require t::testapp::lib::Site;

Site::reset_database();


Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $site = "http://127.0.0.1:$port";
        my $ua = LWP::UserAgent->new;
        $ua->cookie_jar({file => "cookies.txt"});
        push @{ $ua->requests_redirectable }, 'POST';
        my $res = $ua->post($site . "/admin/login", { user => 'admin', password => 'admin' });
        $res = $ua->post($site . "/admin/user/add",
                         { 'user' => 'dummy',
                           'password' => 'dummy',
                           'password-confirm' => 'dummy',
                           'role' => 'editor' });
        is($res->code, 200, "User creation returned 200");
        like($res->decoded_content, qr/<td>dummy<\/td>/, "Dummy in users list");
        $res = $ua->get($site . "/admin/logout");
        $res = $ua->post($site . "/admin/login", { user => 'dummy', password => 'dummy' });
        like($res->decoded_content, qr/<b class="icon-user"><\/b>.*dummy/, "Logged as dummy");
        $res = $ua->get($site . "/admin/user/password");
        is($res->code, 200, "Change password page correctly called"); 
        $res = $ua->post($site . "/admin/user/password",
                         { 'password' => 'changed',
                           'password-confirm' => 'changed' });
        is($res->code, 200, "Password changed");
        $res = $ua->get($site . "/admin/logout");
        $res = $ua->post($site . "/admin/login", { user => 'dummy', password => 'changed' });
        like($res->decoded_content, qr/<b class="icon-user"><\/b>.*dummy/, "Logged as dummy with the new password");
    },
    server => sub {
        my $port = shift;
        use Dancer2;
        Dancer2->runner->{'port'} = $port;
        start;
    },
);

done_testing;
