package Strehler::Element::Role::Maintainer;

use strict;
use Moo::Role;
use SQL::Translator;
use SQL::Translator::Parser::DBIx::Class;

requires 'install';

sub deploy_entity_on_db
{
    my $self = shift;
    my $dbh = shift;
    my $entities = shift;

    my $schema = Strehler::Schema->connect(sub {return $dbh });
    my $producer = $dbh->{Driver}->{Name};
    $producer = "MySQL" if $producer eq 'mysql';

    my $trans1  = SQL::Translator->new (
      parser      => 'SQL::Translator::Parser::DBIx::Class',
      parser_args => {
          dbic_schema => $schema,
          no_comments => 1,
      },
      producer    => $producer
    ) or print SQL::Translator->error;
    
    my @already_done_queries = $trans1->translate();

    foreach my $table (@{$entities})
    {
        print "Working on $table...\n";
        my $added = $table;
        eval("use $added");
        my $table_name = $table;
        $table_name =~ s/^.*:://;
        $schema->register_class($table_name, $added);

        my $new_trans  = SQL::Translator->new (
            parser      => 'SQL::Translator::Parser::DBIx::Class',
            parser_args => {
                dbic_schema => $schema,
                no_comments => 1,
            },
            producer    => $producer
        ) or print SQL::Translator->error;
        my %already_done = map {$_ => 1} @already_done_queries;
        my @todo  = grep {not $already_done{$_}} $new_trans->translate();
        foreach my $q (@todo)
        {
            $dbh->do($q) or print $dbh->errstr . "\n";
        }
        @already_done_queries = $new_trans->translate();
    }
}

=encoding utf8

=head1 NAME

Strehler::Element::Role::Maintainer - Maintainer role

=head1 DESCRIPTION

This role is used only during entity installation. It requires an install method to be implemented. Install method will be called by strehler script when used with the command initentity.

This role was introduced to collect helpers and introspective methods useful for installation.

=head1 INSTALL METHOD

    strehler initentity My::Entity::Maintained

Using strehler script this way the system call the install method implemented in the entity passing as parameters the database handler defined using Dancer2 configuration and public directory. This two elements can be used to customize the enviroment as for entity requests.

=head1 HELPERS

=head2 DEPLOY_ENTITY_ON_DB

arguments: $dbh, $schema_classes

    $class->deploy_entity_on_db($dbh, ['My::Entity::Schema', 'My::Entity::Multilang::Schema']);

You can use this method to add new tables to site database. Define needed tables through DBIx::Schema classes, that call the method with the database handler and an array containing class names. Tables will be added to the database.

=head3 CAVEATS

Defining classes array, order matters! If you have foreign keys ensure that the table that will be linke is already created. For example, always place main table first and multilang element second.

Writing this methos was a great pain and I had to hack a little many things. I tested it on MySQL and SQLite, but I don't know how it can behave in more exotic environments. Try it and tell me...

=cut

1;




