use utf8;
package Strehler::Schema::Result::ActivityLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Strehler::Schema::Result::ActivityLog

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<ACTIVITY_LOG>

=cut

__PACKAGE__->table("ACTIVITY_LOG");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 user

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 action

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 entity_type

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 entity_id

  data_type: 'integer'
  is_nullable: 1

=head2 timestamp

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "user",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "action",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "entity_type",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "entity_id",
  { data_type => "integer", is_nullable => 1 },
  "timestamp",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2014-03-30 16:02:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7nG5V0Nmw3p00rQnuH8Rhg


# You can replace this text with custom code or comments, and it will be preserved on regeneration

=head1 DESCRIPTION

Module of Strehler::Schema

=cut

1;
