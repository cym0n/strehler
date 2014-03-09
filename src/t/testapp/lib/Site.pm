package Site;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/testapp/lib";
use Dancer2;
use Dancer2::Plugin::DBIC;
use Strehler::Admin;

sub reset_database
{
    schema->resultset('ActivityLog')->delete_all();
    schema->resultset('Article')->delete_all();
    schema->resultset('Category')->delete_all();
    schema->resultset('ConfiguredTag')->delete_all();
    schema->resultset('Content')->delete_all();
    schema->resultset('Description')->delete_all();
    schema->resultset('Image')->delete_all();
    schema->resultset('Tag')->delete_all();
}

1;
