# reported by tokuhirom
use strict;
use warnings;
use Test::More tests => 6;
use Data::Model;
use Data::Model::Driver::DBI;

{
    package Neko::DB::User;
    use base 'Data::Model';
    use Data::Model::Schema;

    install_model user => schema {
        key 'foo';

        column 'foo' => varchar => {
            binary => 1,
        };
    };
}

my $dm = Neko::DB::User->new();
my $driver = Data::Model::Driver::DBI->new(
    dsn => 'dbi:SQLite:'
);
$dm->set_base_driver($driver);

for my $target ($dm->schema_names) {
    for my $sql ($dm->as_sqls($target)) {
        $driver->rw_handle->do($sql);
    }
}

ok 1;

my $ret;
ok($dm->set( user => 'foo' ), 'set user foo');
ok($dm->set( user => 'Foo' ), 'set user Foo');

($ret) = $dm->get( user => 'foo' );
is($ret->foo, 'foo', 'get user foo');
($ret) = $dm->get( user => 'Foo' );
is($ret->foo, 'Foo', 'get user Foo');

($ret) = $dm->get( user => 'FOO' );
ok(!$ret, 'FOO is not found in user');
