use utf8;
package Site::SiteDB::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Site::SiteDB::Result::User

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

=head1 TABLE: C<USERS>

=cut

__PACKAGE__->table("USERS");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 user

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 password_hash

  data_type: 'char'
  is_nullable: 1
  size: 31

=head2 password_salt

  data_type: 'char'
  is_nullable: 1
  size: 22

=head2 role

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "user",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "password_hash",
  { data_type => "char", is_nullable => 1, size => 31 },
  "password_salt",
  { data_type => "char", is_nullable => 1, size => 22 },
  "role",
  { data_type => "varchar", is_nullable => 1, size => 50 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2013-12-29 17:57:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:m52d4HXfOKbRj3sOkb25Kw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
