use strict;
use warnings;

use lib "lib";
use lib "t/testapp/lib";

use Test::More;
use Plack::Builder;
use Plack::Test;
use HTTP::Request;
use HTTP::Request::Common;
use HTTP::Cookies;
use Data::Dumper;

$ENV{DANCER_CONFDIR} = 't/testapp';
require Strehler::Admin;

my $app = Strehler::Admin->to_app;

test_psgi $app, sub {
    my $cb = shift;
    my $jar = HTTP::Cookies->new;
    my $site = "http://localhost";

    my $r = $cb->( GET '/admin' );
    is(
        $r->code,
        302,
        'Not logged user call is redirected'
    );
    is(
        $r->headers->header('Location'),
        $site . '/admin/login',
        'Not logged user call is redirected on login page',
    );

    $r = $cb->( POST '/admin/login', [ user => 'admin', password => 'wrongpassword' ] );
    like($r->decoded_content, qr/Authentication failed!/, "Inserting wrong credentials at login gives an error");

    $r = $cb->( POST '/admin/login', [ user => 'admin', password => 'admin' ] );
    $jar->extract_cookies($r);
    my $req = HTTP::Request->new(GET => $site . '/admin');
    $jar->add_cookie_header($req);
    $r = $cb->($req); 
    like($r->decoded_content, qr/<b class="icon-user"><\/b>.*admin/, "Inserting correct credentials at login leads to Strehler homepage");
};

done_testing;

