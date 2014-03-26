package Demo;
use Dancer2;
use Strehler::Dancer2::Plugin;


get '/' => sub {
    template 'strehler-home';
};

true;
