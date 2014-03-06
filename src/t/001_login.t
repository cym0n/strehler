use strict;
use warnings;

use Test::More;
use Test::TCP;
use LWP::UserAgent;
use FindBin;

use t::testapp::lib::Site;


Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $site = "http://127.0.0.1:$port";
        my $ua = LWP::UserAgent->new;
        $ua->cookie_jar({file => "cookies.txt"});
        push @{ $ua->requests_redirectable }, 'POST';
        my $res = $ua->get($site . "/admin");
        ok($res->is_success, "Calling Strehler home with non-logged user redirect to login page");
        $res = $ua->post($site . "/admin/login", { user => 'admin', password => 'admin' });
        like($res->decoded_content, qr/<b class="icon-user"><\/b>.*admin/, "Inserting correct credentials at login leads to Strehler homepage");

    },
    server => sub {
        my $port = shift;
        use Dancer2;
        set(show_errors  => 1,
            startup_info => 1,
            port         => $port,
            logger       => 'capture',
            log          => 'debug',
        );
        Site->runner->server->port($port);
        start;
    },
);

done_testing;
