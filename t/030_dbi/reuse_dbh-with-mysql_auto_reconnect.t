use strict;
use warnings;
use Test::More;
use Data::Model;
use Data::Model::Driver::DBI;

plan skip_all => "Set TEST_MYSQL environment variable to run this test"
    unless $ENV{TEST_MYSQL};
plan tests => 17;

my $driver1 = Data::Model::Driver::DBI->new(
    dsn             => 'dbi:mysql:database=test',
    connect_options => { mysql_auto_reconnect => 1 },
    reuse_dbh       => 1,
);

my $driver2 = Data::Model::Driver::DBI->new(
    dsn             => 'dbi:mysql:database=test',
    connect_options => { mysql_auto_reconnect => 1 },
    reuse_dbh       => 1,
);

my $driver3 = Data::Model::Driver::DBI->new(
    dsn       => 'dbi:mysql:database=test',
);

is($driver1->rw_handle, $driver2->rw_handle, 'driver1 == driver2');
isnt($driver1->rw_handle, $driver3->rw_handle, 'driver1 != driver3');
isnt($driver2->rw_handle, $driver3->rw_handle, 'driver2 != driver3');
is($driver1->rw_handle, $driver2->rw_handle, 'driver1 == driver2');

my $driver1_old_handle = $driver1->rw_handle;
$driver1->rw_handle->disconnect;
ok($driver1_old_handle->ping, 'ping driver1');
is($driver1_old_handle, $driver1->rw_handle, 'driver1_old_handle == driver1');
ok($driver1->rw_handle->ping, 'ping driver1');

my $driver2_old_handle = $driver2->rw_handle;
$driver2->rw_handle->disconnect;
ok($driver2_old_handle->ping, 'ping driver2');
is($driver2_old_handle, $driver2->rw_handle, 'driver2_old_handle == driver2');
ok($driver2->rw_handle->ping, 'ping driver2');

my $driver3_old_handle = $driver3->rw_handle;
$driver3->rw_handle->disconnect;
ok(!$driver3_old_handle->ping, '! ping driver3');
isnt($driver3_old_handle, $driver3->rw_handle, 'driver3_old_handle != driver3');
ok($driver3->rw_handle->ping, 'ping driver3');


is($driver1->rw_handle, $driver2->rw_handle, 'driver1 == driver2');
isnt($driver1->rw_handle, $driver3->rw_handle, 'driver1 != driver3');
isnt($driver2->rw_handle, $driver3->rw_handle, 'driver2 != driver3');
is($driver1->rw_handle, $driver2->rw_handle, 'driver1 == driver2');
