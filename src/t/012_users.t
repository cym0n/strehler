use strict;
use warnings;

use lib "lib";
use lib "t/testapp/lib";

use Test::More;
use Plack::Builder;
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Cookies;

$ENV{DANCER_CONFDIR} = 't/testapp';
require Strehler::Admin;
require t::testapp::lib::TestSupport;

TestSupport::reset_database();

my $app = Strehler::Admin->to_app;

test_psgi $app, sub {
    my $cb = shift;
    my $jar = HTTP::Cookies->new;
    my $site = "http://localhost";
    my $r;

    #User creation
    ($r, $jar) = TestSupport::keep_logged($cb, $jar, POST $site . "/admin/login", [ user => 'admin', password => 'admin']); 
    ($r, $jar) = TestSupport::keep_logged($cb, $jar, POST $site . "/admin/user/add",
                                            [ 'user' => 'dummy',
                                              'password' => 'dummy',
                                              'password-confirm' => 'dummy',
                                              'role' => 'editor' ]);
    ($r, $jar) = TestSupport::keep_logged($cb, $jar, GET $site . "/admin/user/list");
    like($r->decoded_content, qr/<td>dummy<\/td>/, "Dummy in users list");

    #User access
    $jar = HTTP::Cookies->new;
    ($r, $jar) = TestSupport::keep_logged($cb, $jar, POST $site . "/admin/login", [ user => 'dummy', password => 'dummy']); 
    ($r, $jar) = TestSupport::keep_logged($cb, $jar, GET $site . "/admin"); 
    like($r->decoded_content, qr/<b class="icon-user"><\/b>.*dummy/, "Logged as dummy");
    ($r, $jar) = TestSupport::keep_logged($cb, $jar, GET $site . "/admin/user/password");
    is($r->code, 200, "Change password page correctly called");  
    ($r, $jar) = TestSupport::keep_logged($cb, $jar, POST $site . "/admin/user/password",
                                            [ 'password' => 'changed',
                                              'password-confirm' => 'changed' ]); 

    #User access with new password                                      
    $jar = HTTP::Cookies->new;
    ($r, $jar) = TestSupport::keep_logged($cb, $jar, POST $site . "/admin/login", [ user => 'dummy', password => 'changed']); 
    ($r, $jar) = TestSupport::keep_logged($cb, $jar, GET $site . "/admin"); 
    like($r->decoded_content, qr/<b class="icon-user"><\/b>.*dummy/, "Logged as dummy with the new password");
};
done_testing;
