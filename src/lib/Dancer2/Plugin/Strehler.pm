package Dancer2::Plugin::Strehler;
use Dancer2::Plugin;
use Data::Dumper;

on_plugin_import {
    my $dsl = shift;
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
    };

register_plugin for_versions => [ 2 ];

1;

