use utf8;
package Site::SiteDB::Result::Tag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Site::SiteDB::Result::Tag

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

=head1 TABLE: C<TAGS>

=cut

__PACKAGE__->table("TAGS");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 tag

  data_type: 'varchar'
  is_nullable: 1
  size: 120

=head2 item_id

  data_type: 'integer'
  is_nullable: 1

=head2 item_type

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "tag",
  { data_type => "varchar", is_nullable => 1, size => 120 },
  "item_id",
  { data_type => "integer", is_nullable => 1 },
  "item_type",
  { data_type => "varchar", is_nullable => 1, size => 20 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2014-01-25 12:20:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:V3n9TiNM4eN6sttVOkwWCw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
