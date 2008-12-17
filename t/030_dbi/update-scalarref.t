use t::Utils;
use Data::Model::Driver::DBI;

my $dsn = 'dbi:SQLite:dbname=' . temp_filename;;
my $driver = Data::Model::Driver::DBI->new(
    dsn => $dsn,
    username => '',
    password => '',
);
my $model = MyModel->new;

{
    package MyModel;
    use base 'Data::Model';
    use Data::Model::Schema;

    install_model counter => schema {
        driver $driver;
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

{
    package MyTest;
    use base 'Test::Class';
    use Test::More;

    sub t_01_normal_update : Tests(4) {
        my($obj) = $model->get( counter => 1 );
        is($obj->count, 0, 'count 0');
        $obj->count( $obj->count + 1 );
        is($obj->count, 1, 'count 1');
        $obj->update;
        is($obj->count, 1, 'count 1');

        my($obj2) = $model->get( counter => 1 );
        is($obj2->count, 1, 'count 1');
    }

    sub t_02_direct_update : Tests(3) {
        my($obj) = $model->get( counter => 1 );
        is($obj->count, 1, 'count 1');

        ok $model->update( counter => 1 => undef => {
            count => \'count + 1',
        }), 'direct update';

        my($obj2) = $model->get( counter => 1 );
        is($obj2->count, 2, 'count 2');
    }
}

setup_schema( $dsn => MyModel->as_sqls );
$model->set( 'counter' );
MyTest->runtests;
