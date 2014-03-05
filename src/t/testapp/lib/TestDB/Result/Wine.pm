use utf8;
package TestDB::Result::Wine;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

TestDB::Result::Wine

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

=head1 TABLE: C<WINES>

=cut

__PACKAGE__->table("WINES");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 year

  data_type: 'varchar'
  is_nullable: 1
  size: 4

=head2 region

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 winery

  data_type: 'integer'
  is_nullable: 1

=head2 category

  data_type: 'integer'
  is_nullable: 1

=head2 published

  data_type: 'tinyint'
  is_nullable: 1

=head2 display_order

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "year",
  { data_type => "varchar", is_nullable => 1, size => 4 },
  "region",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "winery",
  { data_type => "integer", is_nullable => 1 },
  "category",
  { data_type => "integer", is_nullable => 1 },
  "published",
  { data_type => "tinyint", is_nullable => 1 },
  "display_order",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2014-02-05 22:38:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NxGA3o3KYAPD9mz1dcIxzw


# You can replace this text with custom code or comments, and it will be preserved on regeneration

__PACKAGE__->belongs_to(
  "winery_ref",
  "TestDB::Result::Winery",
  { id => "winery" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);

__PACKAGE__->belongs_to(
  "category",
  "TestDB::Result::Category",
  { id => "category" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);

__PACKAGE__->has_many(
  "winemulti",
  "TestDB::Result::WineMulti",
  { "foreign.wine" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
1;
