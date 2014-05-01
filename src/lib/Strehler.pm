use strict;
use warnings;
package Strehler;
{
  $Strehler::VERSION = '1.1.7';
}

# ABSTRACT: A light-weight, nerdy, smart CMS in perl based on Perl Dancer2 framework.

=encoding utf8

=head1 NAME

Strehler - A light-weight, nerdy, smart CMS in perl based on Perl Dancer2 framework.

=head1 DESCRIPTION

Strehler is a module that add to your Dancer2 app a simple backend to edit contents. 

It can be used to manage articles and images and arrange them with categories and tags.

You can easly extend Strehler to add features or to manage through its interface contents different from the ones already provided.

=head1 SYNOPSIS

    cpan -i Strehler

    strehler demo

    cd StrehlerDemo

    bin/app.pl

Open a browser and go to http://localhost:3000/admin. As login use username: admin and password: admin. 

Welcome to Strehler! Here you can write contents. Study the documentation about how to develope a site to display them.

=head1 STREHLER SCRIPT

Strehler is shipped with a script to make easy initialization and configuration of the system. You can use it on an existing Dancer2 app to add Strehler powers to it.

=head2 Available commands

Strehler script commands are

=over 4

=item commands 

Just to see this list on the command-line.

=item statics 

Go in the root directory of your Dancer2 app and type

    strehler statics

This command will copy static resources used by Strehler in the public directory of the app. If you decided to use a different directory for static files just add its name to the command.

    strehler statics other-directory

Using strehler statics on your app is MANDATORY to use Strehler capabilities.

=item initdb 

Go in the root directory of your Dancer2 app, ensure you have in it a config.yml with a Dancer2::Plugin::DBIC configured and type

    strehler initdb

The script will take the default schema configured in your config.yml and it will deploy in it Strehler database tables. 

B<Warning>: This will erase every previous table created with the name of a Strehler table. Create commands have a DROP IF EXISTS on top.

If you configured different schemas in your config.yml and you want Strehler to deploy itself in one different from the default just add its name to the script.

    strehler initdb other-schema

If you want to work with the configurations of an environment different from the default one (development) just launch the command as

    DANCER_ENVIRONMENT=other-env strehler initdb

During database initialization you'll have to choose your admin password. Use it to enter Strehler admin interface (username: admin)

Using strehler initdb on your app is MANDATORY to use Strehler capabilities.

=item layout 

Go in the root directory of your Dancer2 app and type

    strehler layout

This will just copy the strehler layout file in your views/layouts directory. This file is only needed here if you want to customize Strehler, changing its homepage or adding navigations others the the ones already implemented. Otherwise, you can avoid this command.

=item demo

Just type

    strehler demo

It will create a Dancer2 app named StrehlerDemo and then it will run on it C<strehler statics>, C<strehler initdb> and C<strehler layout>. Then some demo files will be added.

If you want the app to be deployed in a directory different from StrehlerDemo just type

    strehler demo other-directory

When installation is finished go under the newly created app and type

    bin/app.pl

With your browser go to http://localhost:3000/admin, use "admin" as username and "admin" as password and try out Strehler!

=back

=head1 HOW TO ADD STREHLER TO AN APP

You already have a Dancer2 app correctly generated using Dancer2 tutorials. You also have Dancrr2::Plugin::DBIC configured.

Now go under root directory on your app and type

    strehler statics

And then

    strehler initdb

During initdb running password for admin will be requested. Choose one and remember it.

For database schema you have to ways. You can just configure in the plugin the schema as Strehler::Schema. It will works well if you have no intention to add tables other than the ones provided by Strehler.
Other possibility is to create a schema using dbicdump script of DBIx::Class::Schema::Loader, dumping Strehler tables along with all the others you created.

Finally open your bin/app.pl and add the line

    use Strehler::Admin

I<below> the use directive about your main app. Placing it below it (and not above) is important to keep Dancer2 to consider right paths and configurations.

Done!
Now at the url http://YOURAPP/admin you'll find Strehler backend!

=head1 COMPLETE DOCUMENTATION

For now, best place to learn how Strehler works is the github wiki: L<https://github.com/cym0n/strehler/wiki>

=cut


1;
