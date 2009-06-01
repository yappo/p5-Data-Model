use t::Utils;
use Data::Model::Driver::DBI::MasterSlave;

my $master_dsn = 'dbi:SQLite:dbname=' . temp_filename;
my $slave_dsn  = 'dbi:SQLite:dbname=' . temp_filename;
my $driver = Data::Model::Driver::DBI::MasterSlave->new(
    master => {
        dsn => $master_dsn,
        username => '',
        password => '',
    },
    slave  => {
        dsn => $slave_dsn,
        username => '',
        password => '',
    },
);

{
    package MyModel;
    use base 'Data::Model';
    use Data::Model::Schema;

    base_driver $driver;
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

    install_model user => schema {
        key 'name';

        columns qw/ name nickname /;

        schema_options create_sql_attributes => {
            mysql => 'TYPE=InnoDB',
        };
    };
}

my $model = MyModel->new;
{
    package MyTest;
    use base 'Test::Class';
    use Test::More;

    sub force_master_access (&) {
        no warnings 'redefine';
        local *Data::Model::Driver::DBI::MasterSlave::r_handle = \&Data::Model::Driver::DBI::MasterSlave::rw_handle;
        $_[0]->();
    }

    sub t_01_insert : Tests(4) {
        my($obj) = $model->set( 'counter' );
        ok($obj, 'set');

        my $slave_get = $model->get( counter => 1 );
        ok(!$slave_get, 'slave get');

        force_master_access {
            my($master_get) = $model->get( counter => 1 );
            ok($master_get, 'master get');
            is($master_get->count, 0, 'master count is 0');
        };
    }

    sub t_02_update : Tests(3) {
        my $update = $model->update( counter => 1, undef, { count => 100 } );
        ok($update, 'update');

        force_master_access {
            my($master_get) = $model->get( counter => 1 );
            ok($master_get, 'master get');
            is($master_get->count, 100, 'master count is 100');
        };
    }

    sub t_03_delete : Tests(2) {
        my $delete = $model->delete( counter => 1 );
        ok($delete, 'delete');

        force_master_access {
            my($master_get) = $model->get( counter => 1 );
            ok(!$master_get, 'master get');
        };
    }

    sub t_11_transaction : Tests(11) {
        isnt($model->get_base_driver->rw_handle, $model->get_base_driver->r_handle, 'rw_handle != r_handle');
        
        my $scope = $model->txn_scope;
        is($model->get_base_driver->rw_handle, $model->get_base_driver->r_handle, 'rw_handle == r_handle');
        $scope->rollback;
        isnt($model->get_base_driver->rw_handle, $model->get_base_driver->r_handle, 'rw_handle != r_handle');

        $model->txn_scope;
        isnt($model->get_base_driver->rw_handle, $model->get_base_driver->r_handle, 'rw_handle != r_handle');

        do {
            my $scope = $model->txn_scope;
            is($model->get_base_driver->rw_handle, $model->get_base_driver->r_handle, 'rw_handle == r_handle');
        };
        isnt($model->get_base_driver->rw_handle, $model->get_base_driver->r_handle, 'rw_handle != r_handle');


        $scope = $model->txn_scope;
        $scope->set( user => { name => 'osawa', nickname => 'yappo' } );
        my($get) = $scope->get( user => 'osawa' );
        is($get->nickname, 'yappo', 'get from rw_handle');
        $scope->commit;
        isnt($model->get_base_driver->rw_handle, $model->get_base_driver->r_handle, 'rw_handle != r_handle');

        ($get) = $model->get( user => 'osawa' );
        ok(!$get, 'get from r_handle');

        $scope = $model->txn_scope;
        ($get) = $scope->get( user => 'osawa' );
        is($get->nickname, 'yappo', 'get from rw_handle');
        $scope->rollback;

        ($get) = $model->get( user => 'osawa' );
        ok(!$get, 'get from r_handle');
    }
}

setup_schema( $master_dsn => MyModel->as_sqls );
setup_schema( $slave_dsn  => MyModel->as_sqls );
MyTest->runtests;
