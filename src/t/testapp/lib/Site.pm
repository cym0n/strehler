package Site;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/testapp/lib";
use Dancer2;
use Strehler::Dancer2::Plugin::EX;
use Strehler::Admin;
use Strehler::API;

set views => "$FindBin::Bin/testapp/views";

slug '/ex/slug/:slug', 'element';
list '/ex/list/dummy', 'dummy_list', 'dummy';
latest_page '/ex/mypage', 'mypage', { upper => 'upper', lower => 'lower' };
slug '/exref/slug/:slug', 'element', { category => 'dummy' };
list '/exref/list/dummy', 'dummy_list', { category => 'dummy' };
latest_page '/exref/mypage', 'mypage', { upper => { category => 'upper' }, lower => { category => 'lower' } };

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
get '/dummyslug/:slug' => sub {
    my $a = Site::Dummy->get_by_slug(params->{'slug'}, undef);
    my %data = $a->get_ext_data(params->{'lang'});
    return $data{'id'};
};

1;
