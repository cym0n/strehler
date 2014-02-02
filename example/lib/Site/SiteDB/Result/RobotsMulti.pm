use utf8;
package Site::SiteDB::Result::RobotsMulti;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Site::SiteDB::Result::RobotsMulti

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

=head1 TABLE: C<ROBOTS_MULTI>

=cut

__PACKAGE__->table("ROBOTS_MULTI");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 robot

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 story

  data_type: 'varchar'
  is_nullable: 1
  size: 120

=head2 description

  data_type: 'varchar'
  is_nullable: 1
  size: 120

=head2 language

  data_type: 'varchar'
  is_nullable: 1
  size: 2

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "robot",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "story",
  { data_type => "varchar", is_nullable => 1, size => 120 },
  "description",
  { data_type => "varchar", is_nullable => 1, size => 120 },
  "language",
  { data_type => "varchar", is_nullable => 1, size => 2 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 robot

Type: belongs_to

Related object: L<Site::SiteDB::Result::Robot>

=cut

__PACKAGE__->belongs_to(
  "robot",
  "Site::SiteDB::Result::Robot",
  { id => "robot" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2014-02-01 23:28:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ep6t6QFjig6aAaS+mLrT1w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
