package Strehler;

use strict;
use warnings;

# ABSTRACT: A light-weight, nerdy, smart CMS in perl based on Perl Dancer2 framework.

our $STATICS_VERSION = 2;

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

Before using any strehler command go in the directory where your Dancer2 app is and type

    export DANCER_CONFDIR=.

Then do anything you want staying in the root dir of the Dancer app.

=head2 Available commands

Strehler script commands are

=over 4

=item commands 

Just to see this list on the command-line.

=item statics 

Go in the root directory of your Dancer2 app and type

    strehler statics

This command will copy static resources used by Strehler in the public directory of the app. 

Using strehler statics on your app is MANDATORY to use Strehler capabilities.

strehler statics is included in strehler batch.

B<Warning>: every time you run strehler statics the %PUBLIC%/strehler directory is removed and copied as new from the package. Do not use strehler directory for your files if you think you could run strehler statics more than once (for example, updating package)

=item initdb 

Go in the root directory of your Dancer2 app, ensure you have in it a config.yml with a Dancer2::Plugin::DBIC configured and type

    strehler initdb

The script will take the schema configured as Strehler schema in your config.yml (or default) and it will deploy in it Strehler database tables. 

B<Warning>: This will erase every previous table created with the name of a Strehler table. Create commands have a DROP IF EXISTS on top.

If you want to work with the configurations of an environment different from the default one (development) just launch the command as

    DANCER_ENVIRONMENT=other-env strehler initdb

During database initialization you'll have to choose your admin password. Use it to enter Strehler admin interface (username: admin). This password can be changed using pwdchange.

Using strehler initdb on your app is MANDATORY to use Strehler capabilities.

Strehler statics is included in strehler batch.

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

=item pwdchange

Type 
    
    strehler pwdchange

A new password for admin user will be asked. New password will substitute the old one.

Only admin password can be changed.

=item schemadump

    strehler schemadump

Just run dbicdump using Dancer2::Plugin::DBIC configuration to setup database models. Do nothing is Strehler::Schema is the configured schema class.

schemadump is included in strehler batch.

=item batch

    strehler batch

This command executes initdb, statics and, if needed, schemadump. Schemadump is executed only if configured schema class for database is different from Strehler::Schema. 

Typing batch you can setup a Strehler environment with just one command.

=item categories
    
    strehler categories FILE

Provide to categories command a file like this:

    robots/giant robots
        article;good,evil;good
        image;pilot,machine
    robots/androids
    robots
        all;japanese,american;japanese
    robots/mech
    spaceships
    planets/bases
    planets/cities
    robots/androids

This will generate on the database all the categories. 

An indented line (with spaces) under category name configure tags with this pattern:

%ENTITY%;%TAGS%,%SEPARATED%,%BY%,%COMMAS%;%DEFAULT%

If a category is present in the file more than one time, last configuration wins.

If a category is present in the file more than one time, last configuration will be used.

Using this script, categories can only be created, never erased. A tags configuration different from the one in the db will overwrite that with no warning.

If you specify a parent that doesn't exists, the new parent will be created.

Default file name is categories.txt, this file will be used if no filename is provided.

=item testelement

    strehler testelement Strehler::Element::Article

Run a check about configuration of an entity. Useful when new entity are written for a specific site.

=item initentity

    strehler initentity Strehler::Element::Extra::Artwork

Considering a non-standard entity installed from a package different from Strehler. 

Initelement run the install method of the class, allowing entity initialization if needed.

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

From start to here, all the procedure can be done just typing:

    strehler batch

Finally open your bin/app.pl and add the line

    use Strehler::Admin

I<below> the use directive about your main app. Placing it below it (and not above) is important to keep Dancer2 to consider right paths and configurations.

Done!
Now at the url http://YOURAPP/admin you'll find Strehler backend!

=head1 COMPLETE DOCUMENTATION

For now, best place to learn how Strehler works is the github wiki: L<https://github.com/cym0n/strehler/wiki>

=head1 AUTHOR

Simone "Cymon" Fare'

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Simone "Cymon" Fare'.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


1;
