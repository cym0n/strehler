use strict;
use warnings;

use Test::More;
use Test::TCP;
use LWP::UserAgent;
use FindBin;

$ENV{DANCER_CONFDIR} = 't/testapp';
require t::testapp::lib::Site;


Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $site = "http://127.0.0.1:$port";
        my $ua = LWP::UserAgent->new;
        $ua->cookie_jar({file => "cookies.txt"});
        push @{ $ua->requests_redirectable }, 'POST';
        my $res = $ua->get($site . "/admin");
        is($res->base, $site . "/admin/login", "Calling Strehler home with non-logged user redirect on login page");
        $res = $ua->post($site . "/admin/login", { user => 'admin', password => 'wrongpassword' });
        like($res->decoded_content, qr/Authentication failed!/, "Inserting wrong credentials at login gives an error");
        $res = $ua->post($site . "/admin/login", { user => 'admin', password => 'admin' });
        like($res->decoded_content, qr/<b class="icon-user"><\/b>.*admin/, "Inserting correct credentials at login leads to Strehler homepage");
    },
    server => sub {
        my $port = shift;
        use Dancer2;
        Dancer2->runner->{'port'} = $port;
        start;
    },
);

done_testing;
