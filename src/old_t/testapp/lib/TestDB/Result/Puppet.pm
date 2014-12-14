use utf8;
package TestDB::Result::Puppet;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

TestDB::Result::Puppet

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

=head1 TABLE: C<PUPPET>

=cut

__PACKAGE__->table("PUPPET");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 text

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 display_order

  data_type: 'integer'
  is_nullable: 1

=head2 publish_date

  data_type: 'date'
  is_nullable: 1

=head2 published

  data_type: 'tinyint'
  is_nullable: 1
  size: 1

=head2 slug

  data_type: 'varchar'
  is_nullable: 1
  size: 120

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "text",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "display_order",
  { data_type => "integer", is_nullable => 1 },
  "publish_date",
  { data_type => "date", is_nullable => 1 },
  "published",
  { data_type => "tinyint", is_nullable => 1, size => 1 },
  "slug",
  { data_type => "varchar", is_nullable => 1, size => 120 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2014-07-16 01:17:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZvsBdLhXSdo9wSQ7yjDpZw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
