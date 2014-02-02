use utf8;
package Site::SiteDB::Result::Robot;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Site::SiteDB::Result::Robot

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

=head1 TABLE: C<ROBOTS>

=cut

__PACKAGE__->table("ROBOTS");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 pilot

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 strenght

  data_type: 'integer'
  is_nullable: 1

=head2 speed

  data_type: 'integer'
  is_nullable: 1

=head2 defence

  data_type: 'integer'
  is_nullable: 1

=head2 category

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 published

  data_type: 'tinyint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "pilot",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "strenght",
  { data_type => "integer", is_nullable => 1 },
  "speed",
  { data_type => "integer", is_nullable => 1 },
  "defence",
  { data_type => "integer", is_nullable => 1 },
  "category",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "published",
  { data_type => "tinyint", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 category

Type: belongs_to

Related object: L<Site::SiteDB::Result::Category>

=cut

__PACKAGE__->belongs_to(
  "category",
  "Site::SiteDB::Result::Category",
  { id => "category" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);

=head2 robots_multis

Type: has_many

Related object: L<Site::SiteDB::Result::RobotsMulti>

=cut

__PACKAGE__->has_many(
  "robots_multis",
  "Site::SiteDB::Result::RobotsMulti",
  { "foreign.robot" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2014-02-01 23:28:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:B/1cebMDj/JAR8GFExE+Zg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
