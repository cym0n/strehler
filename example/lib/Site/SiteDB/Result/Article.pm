use utf8;
package Site::SiteDB::Result::Article;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Site::SiteDB::Result::Article

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

=head1 TABLE: C<ARTICLES>

=cut

__PACKAGE__->table("ARTICLES");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 image

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 category

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 display_order

  data_type: 'integer'
  is_nullable: 1

=head2 publish_date

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 published

  data_type: 'tinyint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "image",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "category",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "display_order",
  { data_type => "integer", is_nullable => 1 },
  "publish_date",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
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

=head2 contents

Type: has_many

Related object: L<Site::SiteDB::Result::Content>

=cut

__PACKAGE__->has_many(
  "contents",
  "Site::SiteDB::Result::Content",
  { "foreign.article" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2014-01-25 12:20:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uYdEytvIohE6tuBT3mlbHw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
