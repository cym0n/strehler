package Strehler::Dancer2::Plugin;
{
    $Strehler::Dancer2::Plugin::VERSION = '1.0.0';
}
use Dancer2::Plugin;

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
            if(! $dsl->config->{Strehler}->{admin_secured})
            {
                $tokens->{'role'} = 'admin';
                $tokens->{'user'} = 'admin';
            }
            else
            {
                $tokens->{'role'} = $dsl->context->session->read('role');
                $tokens->{'user'} = $dsl->context->session->read('user');
            }
        }));
    };
    

register_plugin for_versions => [ 2 ];

=encoding utf8

=head1 NAME

Strehler::Dancer2::Plugin - Dancer2 Plugin to write new routes in the Strehler Backend

=head1 DESCRIPTION

Dancer2 Strehler plugin allow you to write an app with new routes to be used in Strehler Backend, protected with Strehler login, and rendered with the Strehler context.

This element hasn't the standard Dancer2::Plugin namespace because it makes sense only in a Strehler system.

=head1 SYNOPSIS

    package MyBackend;

    use Dancer2;
    use Strehler::Dancer2::Plugin;

If you want to write a module like this, you have to launch the command

    strehler layout

under your Dancer2 App, to copy Strehler Layout in it, making it available for your developements.

=head1 HOW TO CUSTOMIZE STREHLER BACKEND HOMEPAGE

Strehler homepage is empty e really dump. Probably there're informations you want to display on it or shortcut for your navigation.

To do this you can:

=over 4

=item 1.

Launch strehler layout command in your Dancer2 App.

    strehler layout

=item 2.

Write a view for the homepage like this:

B<views/strelher-home.tt>

    <div class="span10">
        <h1>My wonderful homepage</h1>
        <div>Lorem ipsum...</div> 
    </div>

=item 3.

Write a module with Strehler::Dancer2::Plugin overriding '/' route, calling the new template.

B<lib/MyBackend.pm>

    package MyBackend;
    use Dancer2;
    use Strehler::Dancer2::Plugin;

    get '/' => sub {
        template 'strehler-home';
    };

    true;

=item 4.

Include the module above Strehler::Admin in your application file.

B<bin/app.pl>

    #!/usr/bin/env perl

    use FindBin;
    use lib "$FindBin::Bin/../lib";

    use MyBackend;
    use Strehler::Admin;
    MyBackend->dance;

=back

=cut 

1;

