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
        my $ua = LWP::UserAgent->new;
        my $res = $ua->get("http://127.0.0.1:$port/admin");
        ok($res->is_success);
    },
    server => sub {
        my $port = shift;
        use Dancer2;
        set(show_errors  => 1,
            startup_info => 0,
            port         => $port,
            logger       => 'capture',
            log          => 'debug',
        );
        Site->runner->server->port($port);
        start;
    },
);

done_testing;
