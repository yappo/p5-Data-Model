use t::Utils;
use Test::More tests => 53;

my $dsn = 'dbi:SQLite:dbname=' . temp_filename;

{
    package TestModel;
    use base 'Data::Model';
    use Data::Model::Mixin modules => ['FindOrCreate'];
    use Data::Model::Schema;
    use Data::Model::Driver::DBI;

    my $driver = Data::Model::Driver::DBI->new(
        dsn      => $dsn,
    );
    base_driver $driver;

    install_model test1 => schema {
        key 'id';
        columns qw/id data/;
    };

    install_model test2 => schema {
        key [qw/ id1 id2 /];
        columns qw/id1 id2 data/;
    };
}

my $model = TestModel->new;
setup_schema( $dsn => $model->as_sqls );

do {
    my $set = $model->find_or_create(
        test1 => 'key1' => {
            data => 'data1',
        }
    );
    isa_ok($set, 'TestModel::test1');
    is($set->id, 'key1', 'id');
    is($set->data, 'data1', 'data');

    my $get = $model->find_or_create(
        test1 => 'key1' => {
            data => 'data1',
        }
    );
    isa_ok($get, 'TestModel::test1');
    is($get->id, 'key1', 'id');
    is($get->data, 'data1', 'data');

    my @rows = $model->get( 'test1' );
    is(scalar(@rows), 1, '1 record');

    isa_ok($rows[0], 'TestModel::test1');
    is($rows[0]->id, 'key1', 'id');
    is($rows[0]->data, 'data1', 'data');


    my $set2 = $model->find_or_create(
        test1 => 'key2' => {
            data => 'data2',
        }
    );
    isa_ok($set2, 'TestModel::test1');
    is($set2->id, 'key2', 'id');
    is($set2->data, 'data2', 'data');

    my $get2 = $model->find_or_create(
        test1 => 'key2' => {
            data => 'data2',
        }
    );
    isa_ok($get2, 'TestModel::test1');
    is($get2->id, 'key2', 'id');
    is($get2->data, 'data2', 'data');

    @rows = $model->get( 'test1' );
    is(scalar(@rows), 2, '2 record');

    isa_ok($rows[0], 'TestModel::test1');
    is($rows[0]->id, 'key1', 'id');
    is($rows[0]->data, 'data1', 'data');

    isa_ok($rows[1], 'TestModel::test1');
    is($rows[1]->id, 'key2', 'id');
    is($rows[1]->data, 'data2', 'data');
};

do {
    my $set = $model->find_or_create(
        test2 => [qw/ key10 key20 /] => {
            data => 'data1',
        }
    );
    isa_ok($set, 'TestModel::test2');
    is($set->id1, 'key10', 'id1');
    is($set->id2, 'key20', 'id2');
    is($set->data, 'data1', 'data');

    my $get = $model->find_or_create(
        test2 => [qw/ key10 key20 /] => {
            data => 'data1',
        }
    );
    isa_ok($get, 'TestModel::test2');
    is($get->id1, 'key10', 'id1');
    is($get->id2, 'key20', 'id2');
    is($get->data, 'data1', 'data');

    my @rows = $model->get( 'test2' );
    is(scalar(@rows), 1, '1 record');

    isa_ok($rows[0], 'TestModel::test2');
    is($rows[0]->id1, 'key10', 'id1');
    is($rows[0]->id2, 'key20', 'id2');
    is($rows[0]->data, 'data1', 'data');

    my $set2 = $model->find_or_create(
        test2 => [qw/ key11 key21 /] => {
            data => 'data2',
        }
    );
    isa_ok($set2, 'TestModel::test2');
    is($set2->id1, 'key11', 'id1');
    is($set2->id2, 'key21', 'id2');
    is($set2->data, 'data2', 'data');

    my $get2 = $model->find_or_create(
        test2 => [qw/ key11 key21 /] => {
            data => 'data2',
        }
    );
    isa_ok($get2, 'TestModel::test2');
    is($get2->id1, 'key11', 'id1');
    is($get2->id2, 'key21', 'id2');
    is($get2->data, 'data2', 'data');

    @rows = $model->get( 'test2' );
    is(scalar(@rows), 2, '1 record');

    isa_ok($rows[0], 'TestModel::test2');
    is($rows[0]->id1, 'key10', 'id1');
    is($rows[0]->id2, 'key20', 'id2');
    is($rows[0]->data, 'data1', 'data');

    isa_ok($rows[1], 'TestModel::test2');
    is($rows[1]->id1, 'key11', 'id1');
    is($rows[1]->id2, 'key21', 'id2');
    is($rows[1]->data, 'data2', 'data');
};

