package Site;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/testapp/lib";
use Dancer2;
use Dancer2::Plugin::DBIC;
use Strehler::Admin;

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
}

get '/:lang/get-last-by-order/:cat' => sub {
    my $art = Strehler::Element::Article->get_last_by_order(params->{'cat'}, params->{'lang'});
    my %data = $art->get_ext_data(params->{'lang'});
    return $data{'title'};
};
get '/:lang/get-first-by-order/:cat' => sub {
    my $art = Strehler::Element::Article->get_first_by_order(params->{'cat'}, params->{'lang'});
    my %data = $art->get_ext_data(params->{'lang'});
    return $data{'title'};
};
get '/:lang/get-last-by-date/:cat' => sub {
    my $art = Strehler::Element::Article->get_last_by_date(params->{'cat'}, params->{'lang'});
    my %data = $art->get_ext_data(params->{'lang'});
    return $data{'title'};
};
get '/:lang/get-first-by-date/:cat' => sub {
    my $art = Strehler::Element::Article->get_first_by_date(params->{'cat'}, params->{'lang'});
    my %data = $art->get_ext_data(params->{'lang'});
    return $data{'title'};
};
get '/:lang/slug/:slug' => sub {
    my $a = Strehler::Element::Article->get_by_slug(params->{'slug'}, params->{'lang'});
    my %data = $a->get_ext_data(params->{'lang'});
    return $data{'title'};
};

1;
