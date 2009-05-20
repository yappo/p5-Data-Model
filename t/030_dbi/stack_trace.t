use t::Utils;
use Test::More tests => 7;
use Test::Exception;

use Data::Model::Driver::DBI;

my $dsn = 'dbi:SQLite:dbname=' . temp_filename;
my $driver = Data::Model::Driver::DBI->new(
    dsn => $dsn,
    username => '',
    password => '',
);

{
    package MyModel;
    use base 'Data::Model';
    use Data::Model::Schema;

    base_driver($driver);
    install_model counter => schema {
        key 'id';
        column id
            => int => {
                auto_increment => 1,
            };
        column count
            => int => {
                default => 0,
            };
    };
}
my $model = MyModel->new;
setup_schema( $driver->rw_handle => MyModel->as_sqls );

$model->set( 'counter' );

lives_ok {
    my($ret) = $model->get(
        counter => {
            where => [
                id => 1,
            ],
        },
    );
    is $ret->count, 0, 'get ok';
} 'not died';

throws_ok {
    $model->get(
        counter => {
            where => [
                ids => 1,
            ],
        },
    );
} qr{Data::Model::Driver::DBI 's Exception.+no such column: ids.+SELECT.+WHERE \(ids = \?\).+stack_trace\.t}sm;


throws_ok {
    $model->delete(
        counter => {
            where => [
                ids => 1,
            ],
        },
    );
} qr{Data::Model::Driver::DBI 's Exception.+no such column: ids.+DELETE.+WHERE \(ids = \?\).+stack_trace\.t}sm;


throws_ok {
    $model->update(
        counter => {
            where => [
                ids => 1,
            ],
        },
        {
            count => 1,
        },
    );
} qr{Data::Model::Driver::DBI 's Exception.+no such column: ids.+UPDATE.+WHERE \(ids = \?\).+stack_trace\.t}sm;


throws_ok {
    $model->set(
        counter => {
            ids => 2,
        },
    );
} qr{Data::Model::Driver::DBI 's Exception.+no column named ids.+INSERT.+\(count, ids\).+stack_trace\.t}sm;


throws_ok {
    $model->replace(
        counter => {
            ids => 2,
        },
    );
} qr{Data::Model::Driver::DBI 's Exception.+no column named ids.+REPLACE.+\(count, ids\).+stack_trace\.t}sm;

