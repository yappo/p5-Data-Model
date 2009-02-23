#!/usr/bin/perl
use strict;
use warnings;
use lib 'lib';

use Data::Model::Driver::DBI;
use Getopt::Long;

# opts
GetOptions(
    'model=s' => \my $model_class,
    'from=s'  => \my $from,
    'to=s'    => \my $to,
);
die 'usage: model_converter.pl --model=Your::Model --from=dbi:SQLite:dbname/foo/from.db --t=dbi::SQLite:dbname/foo/to.dbname'
    unless $model_class && $from && $to;

# init
eval "use $model_class";

my($from_dsn, $from_user, $from_password) = split ',', $from;
my $from_driver = Data::Model::Driver::DBI->new(
    dsn      => $from_dsn,
    username => $from_user || '',
    password => $from_password || '',
);

my($to_dsn, $to_user, $to_password) = split ',', $to;
my $to_driver = Data::Model::Driver::DBI->new(
    dsn      => $to_dsn,
    username => $to_user || '',
    password => $to_password || '',
);


# convert
my $model = $model_class->new;
for my $name ($model->schema_names) {
    # create tables
    $model->set_driver( $name => $to_driver );
    $to_driver->rw_handle->do( "DROP TABLE IF EXISTS $name" );
    for my $sql ($model->as_sqls($name)) {
        $to_driver->rw_handle->do( $sql );
    }

    # data convert
    $model->set_driver( $name => $from_driver );
    my $itr = $model->get( $name );
    next unless $itr;
    $model->set_driver( $name => $to_driver );
    while (my $r = $itr->next) {
        $model->set( $name => $r->get_columns );
    }
}
