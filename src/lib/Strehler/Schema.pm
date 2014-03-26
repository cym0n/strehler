use utf8;
package Strehler::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2014-03-15 15:14:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:G9PmftB8XaBv/kqC+m2Ddw


# You can replace this text with custom code or comments, and it will be preserved on regeneration

=encoding utf8

=head1 NAME

Strehler::Schema - DBIx::Class Schema for Strehler database tables

=head1 DESCRIPTION

This is the DBIX::Class schema used to access Strehler database tables. It was created by DBIx::Class::Schema::Loader using a database generated from the SQL scripts written for Strehler. For details about scripts: L<https://github.com/cym0n/strehler/tree/master/SQL>.

=head1 SYNOPSIS

You can directly use this module in your L<Dancer2::Plugin::DBIC> configuration as schema.

    plugins:
        DBIC:
            default:
                dsn: dbi:some:database
                schema_class: Strehler::Schema

=cut

1;
