package Site;
use Dancer2;
use Strehler::Element::Article;
use Strehler::Dancer2::Plugin::EX;
use Data::Dumper;

set layout => 'main';

get '/' => sub {
    template 'home';
};

#get '/article/:slug' => sub {
#    my $slug = params->{'slug'};
#    my $language = config->{'Strehler'}->{'default_language'};
#    my $article = Strehler::Element::Article->get_by_slug($slug, $language);
#    my %data = $article->get_ext_data($language);
#    template 'article', { article => \%data };
#};

get '/article/checktag/:id/:tag' => sub {
    my $id = params->{'id'};
    my $tag = params->{'tag'};
    my $article = Strehler::Element::Article->new($id);
    if($article->has_tag($tag))
    {
        return $article->main_title . " has tag " . $tag;
    }
    else
    {
        return $article->main_title . " hasn't tag " . $tag;
    }
};

slug '/ex/slug/:slug', 'element';
list '/ex/list/dummy', 'dummy_list', 'dummy';
latest_page '/ex/mypage', 'mypage', { upper => 'upper', lower =>  'lower' };
true;
