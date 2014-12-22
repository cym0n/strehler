package TestSupport;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/testapp/lib";
use JSON;
use Dancer2;
use Dancer2::Plugin::DBIC;
use HTTP::Request;
use Data::Dumper;

sub reset_database
{
    my $schema = config->{'Strehler'}->{'schema'} ? schema config->{'Strehler'}->{'schema'} : schema;
    $schema->resultset('ActivityLog')->delete_all();
    $schema->resultset('Article')->delete_all();
    $schema->resultset('Category')->delete_all();
    $schema->resultset('ConfiguredTag')->delete_all();
    $schema->resultset('Content')->delete_all();
    $schema->resultset('Description')->delete_all();
    $schema->resultset('Image')->delete_all();
    $schema->resultset('Tag')->delete_all();
    $schema->resultset('Dummy')->delete_all();
    $schema->resultset('User')->search({ user => { 'not in' => ['admin', 'editor']}})->delete_all();
}

sub keep_logged
{
    my $cb = shift;
    my $jar = shift;
    my $req = shift;
    $jar->add_cookie_header($req);
    my $r = $cb->($req); 
    $jar->extract_cookies($r);
    return ($r, $jar);
}

1;

