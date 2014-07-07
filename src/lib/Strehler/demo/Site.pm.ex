package Site;
use Dancer2;

set layout => 'main';

get '/' => sub {
    template 'home';
};

true;
