use strict;
use warnings;
package Strehler;
{
  $Strehler::VERSION = '1.0.0';
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

=head1 Strehler Script

Strehler is shipped with a script to make easy initialization and configuration of the system. You can use it on an existing Dancer2 app to add Strehler powers to it.

=head2 Available commands

Strehler script commands are

=over 4

=item C<commands> 

Just to see this list on the command-line.

=item C<Statics> 

The default language that will be used when plugin can't guess desired one (or when desired one is not managed)

=cut

=head1 How-To about adding Strehler to an app




1;
