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
        my $res;
        $ua->cookie_jar({file => "cookies.txt"});
        push @{ $ua->requests_redirectable }, 'POST';
        $res = $ua->post($site . "/admin/login", { user => 'editor', password => 'editor' });
        like($res->decoded_content, qr/<b class="icon-user"><\/b>.*editor/, "Login as editor");
        $res = $ua->get($site . "/admin/article/list");
        is($res->code, 200, "Editor can access articles");
        $res = $ua->get($site . "/admin/category/list");
        is($res->code, 403, "Editor can't access cateogries");


    },
    server => sub {
        my $port = shift;
        use Dancer2;
        Dancer2->runner->{'port'} = $port;
        start;
    },
);

done_testing;
