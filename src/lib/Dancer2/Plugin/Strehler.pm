package Dancer2::Plugin::Strehler;
use Dancer2::Plugin;
use Data::Dumper;

on_plugin_import {
    my $dsl = shift;
    $dsl->prefix('/admin');
    $dsl->set(layout => 'admin');
    $dsl->app->add_hook(
        Dancer2::Core::Hook->new(name => 'before', code => sub {
                my $context = shift;
                return if(! $dsl->config->{Strehler}->{admin_secured});
                if((! $context->session->read('user')) && $context->request->path_info ne $dsl->dancer_app->prefix . '/login')
                {
                    $context->session->{'redir_url'} = $context->request->path_info;
                    my $redir = $dsl->redirect($dsl->dancer_app->prefix . '/login');
                    $context->response->is_halted(0);
                    return $redir;
                }
            }));
    $dsl->app->add_hook(
        Dancer2::Core::Hook->new(name => 'before_template_render', code => sub {
            my $tokens = shift;
            my $match_string = "^" . $dsl->dancer_app->prefix . "\/(.*?)\/";
            my $match_regexp = qr/$match_string/;
            my $path = $dsl->request->path_info();
            my $tab;
            if($path =~ $match_regexp)
            {
                $tab = $1;
            }
            else
            {
                $tab = 'home';
            }
            my %navbar;
            $navbar{$tab} = 'active';
            $tokens->{'navbar'} = \%navbar;
            $tokens->{'extramenu'} = $dsl->config->{Strehler}->{'extra_menu'};
        }));
    };
    

register_plugin for_versions => [ 2 ];

1;

