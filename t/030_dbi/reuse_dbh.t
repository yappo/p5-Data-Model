use strict;
use warnings;
use Test::More tests => 4;
use Data::Model;
use Data::Model::Driver::DBI;

my $driver1 = Data::Model::Driver::DBI->new(
    dsn       => 'dbi:SQLite:',
    reuse_dbh => 1,
);

my $driver2 = Data::Model::Driver::DBI->new(
    dsn       => 'dbi:SQLite:',
    reuse_dbh => 1,
);

my $driver3 = Data::Model::Driver::DBI->new(
    dsn       => 'dbi:SQLite:',
);

is($driver1->rw_handle, $driver2->rw_handle, 'driver1 == driver2');
isnt($driver1->rw_handle, $driver3->rw_handle, 'driver1 != driver3');
isnt($driver2->rw_handle, $driver3->rw_handle, 'driver2 != driver3');
is($driver1->rw_handle, $driver2->rw_handle, 'driver1 == driver2');
