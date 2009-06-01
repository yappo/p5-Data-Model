package Mock::Tests::Transaction;
use t::Utils;
use base 'Test::Class';
use Mock::Tests;
use Test::More;

use Data::Model::Driver::Cache;

sub t_01_begin_commit : Tests(11) {
    my $txn = mock->txn_scope;
    isa_ok($txn, 'Data::Model::Transaction');

    my $set = $txn->set( user => { name => 'osawa', nickname => 'yappo' } );
    do {
        my @get = $txn->get( user => { index => { name => 'osawa' } } );
        is(scalar(@get), 1, 'get 1 record');
        ok($get[0], 'get user table id = 1');
        is($get[0]->name, 'osawa', 'name is osawa');
        is($get[0]->nickname, 'yappo', 'nickname is yappo');
    };

    ok($txn->commit, 'commit');

    my @get = mock->get( user => { index => { name => 'osawa' } } );
    is(scalar(@get), 1, 'get 1 record');
    ok($get[0], 'get user table id = 1');
    is($get[0]->name, 'osawa', 'name is osawa');
    is($get[0]->nickname, 'yappo', 'nickname is yappo');
    ok($get[0]->delete, 'delete record');
}

sub t_02_begin_rollback : Tests(7) {
    my $txn = mock->txn_scope;
    isa_ok($txn, 'Data::Model::Transaction');

    my $set = $txn->set( user => { name => 'osawa', nickname => 'yappo' } );
    do {
        my @get = $txn->get( user => { index => { name => 'osawa' } } );
        is(scalar(@get), 1, 'get 1 record');
        ok($get[0], 'get user table id = 2');
        is($get[0]->name, 'osawa', 'name is osawa');
        is($get[0]->nickname, 'yappo', 'nickname is yappo');
    };

    ok($txn->rollback, 'commit');

    my @get = mock->get( 'user' );
    is(scalar(@get), 0, 'user table record is not found');
}

sub t_03_begin_destroy : Tests(5) {
    do {
        my $txn = mock->txn_scope;
        isa_ok($txn, 'Data::Model::Transaction');

        my $set = $txn->set( user => { name => 'osawa', nickname => 'yappo' } );
        do {
            my($get) = $txn->get( user => { index => { name => 'osawa' } } );
            ok($get, 'get user table');
            is($get->name, 'osawa', 'name is osawa');
            is($get->nickname, 'yappo', 'nickname is yappo');
        };
    };

    my @get = mock->get( 'user' );
    is(scalar(@get), 0, 'user table record is not found');
}

sub t_11_set_update_rollback : Tests(4) {
    mock->set( user2 => { name => 'osawa', nickname => 'yappo' } );

    do {
        my $txn = mock->txn_scope;
        my($get) = $txn->lookup( user2 => 'osawa' );
        ok($get, 'get user2 table');
        $get->nickname('yappo2');
        $txn->update($get);

        my($get2) = $txn->lookup( user2 => 'osawa' );
        is($get2->nickname, 'yappo2', 'nickname is yappo2');

        $txn->rollback;
    };

    my($get) = mock->lookup( user2 => 'osawa' );
    is($get->nickname, 'yappo', 'nickname is yappo');
    ok($get->delete, 'delete record');
}

sub t_12_set_update_commit : Tests(4) {
    mock->set( user2 => { name => 'osawa', nickname => 'yappo' } );

    do {
        my $txn = mock->txn_scope;
        my($get) = $txn->lookup( user2 => 'osawa' );
        ok($get, 'get user2 table');
        $get->nickname('yappo2');
        $txn->update($get);

        my($get2) = $txn->lookup( user2 => 'osawa' );
        is($get2->nickname, 'yappo2', 'nickname is yappo2');

        $txn->commit;
    };

    my($get) = mock->lookup( user2 => 'osawa' );
    is($get->nickname, 'yappo2', 'nickname is yappo2');
    ok($get->delete, 'delete record');
}

sub t_13_set_delete_rollback : Tests(4) {
    mock->set( user2 => { name => 'osawa', nickname => 'yappo' } );

    do {
        my $txn = mock->txn_scope;
        my($get) = $txn->lookup( user2 => 'osawa' );
        ok($get, 'get user2 table');
        $txn->delete($get);

        my($get2) = $txn->lookup( user2 => 'osawa' );
        ok(!$get2, 'name = osawa is deleted');

        $txn->rollback;
    };

    my($get) = mock->lookup( user2 => 'osawa' );
    is($get->nickname, 'yappo', 'nickname is yappo');
    ok($get->delete, 'delete record');
}

sub t_14_set_delete_commit : Tests(3) {
    mock->set( user2 => { name => 'osawa', nickname => 'yappo' } );

    do {
        my $txn = mock->txn_scope;
        my($get) = $txn->lookup( user2 => 'osawa' );
        ok($get, 'get user2 table');
        $txn->delete($get);

        my($get2) = $txn->lookup( user2 => 'osawa' );
        ok(!$get2, 'name = osawa is deleted');

        $txn->commit;
    };

    my($get) = mock->lookup( user2 => 'osawa' );
    ok(!$get, 'name = osawa is deleted');
}

# 複合で、色々操作するテスト
sub _t_21_composite_for_cache {
    my($txn, %param) = @_;
    my $m = $txn || mock;
    while (my($model, $data) = each %param) {
        while (my($name, $nickname) = each %{ $data }) {
            my($get) = $m->get( $model, $name );
            is $get->nickname, $nickname, "$model, $name is $nickname";
        }
    }
}

sub t_21_composite_for_cache : Tests(20) {
    mock->set( user2 => { name => 'osawa', nickname => 'yappo' } );
    mock->set( user2 => { name => 'kazuhiro', nickname => 'kazu' } );
    mock->set( user2 => { name => 'hideki', nickname => 'hide' } );
    mock->set( user3 => { name => 'kan', nickname => 'cure' } );
    mock->set( user3 => { name => 'neko', nickname => 'kaku' } );

    my $remove_multi_from_cache_keys;
    my $orig_remove_multi_from_cache = \&Data::Model::Driver::Cache::remove_multi_from_cache;
    no warnings 'redefine';
    local *Data::Model::Driver::Cache::remove_multi_from_cache = sub {
        (undef, $remove_multi_from_cache_keys) = @_;
        $orig_remove_multi_from_cache->(@_);
    };

    _t_21_composite_for_cache 0 => (
        user2 => {
            osawa    => 'yappo',
            kazuhiro => 'kazu',
            hideki   => 'hide',
        },
        user3 => {
            kan  => 'cure',
            neko => 'kaku',
        },
    );

    $remove_multi_from_cache_keys = undef;
    do {
        my $txn = mock->txn_scope;
        $txn->delete( user2 => 'osawa' );
        $txn->update( user3 => 'kan', undef, { nickname => 'pre' } );

        _t_21_composite_for_cache $txn => (
            user2 => {
                kazuhiro => 'kazu',
                hideki   => 'hide',
            },
            user3 => {
                kan  => 'pre',
                neko => 'kaku',
            },
        );
    };
    ok(!$remove_multi_from_cache_keys, 'not delete cache');

    _t_21_composite_for_cache 0 => (
        user2 => {
            osawa    => 'yappo',
            kazuhiro => 'kazu',
            hideki   => 'hide',
        },
        user3 => {
            kan  => 'cure',
            neko => 'kaku',
        },
    );

    $remove_multi_from_cache_keys = undef;
    do {
        my $txn = mock->txn_scope;
        $txn->delete( user2 => 'osawa' );
        $txn->update( user3 => 'kan', undef, { nickname => 'pre' } );
        $txn->commit;
    };
    if (mock->get_base_driver->isa('Data::Model::Driver::Cache')) {
        is_deeply($remove_multi_from_cache_keys, [qw/ user2:osawa user3:kan /], 'deleted cache keys');
    } else {
        ok(1, 'is dummy');
    }

    _t_21_composite_for_cache 0 => (
        user2 => {
            kazuhiro => 'kazu',
            hideki   => 'hide',
        },
        user3 => {
            kan  => 'pre',
            neko => 'kaku',
        },
    );
}


my @model_methods = qw/
    lookup lookup_multi get get_multi
    set set_multi replace update update_direct
    delete delete_direct delete_multi
/;
sub t_51_call_original_model_method : Tests(14) {
    my $txn = mock->txn_scope;

    for my $method (@model_methods, 'txn_scope', 'txn_begin') {
        local $@;
        eval { mock->$method };
        like $@, qr/The '$method' method can not be performed during a transaction./, qq{can't call $method method in model};
    }
}

my @txn_methods = @model_methods;
sub t_52_call_txn_method_out_scope_with_commit : Tests(12) {
    my $txn = mock->txn_scope;
    $txn->commit;

    for my $method (@txn_methods) {
        local $@;
        eval { $txn->$method };
        like $@, qr/You cannot use $method method, Because you leave the transaction scope./, qq{can't call $method method in txn};
    }
}

sub t_53_call_txn_method_out_scope_with_rollback : Tests(12) {
    my $txn = mock->txn_scope;
    $txn->rollback;

    for my $method (@txn_methods) {
        local $@;
        eval { $txn->$method };
        like $@, qr/You cannot use $method method, Because you leave the transaction scope./, qq{can't call $method method in txn};
    }
}


sub t_61_driver_is_base_driver : Tests(1) {
    eval {
        my $txn = mock->txn_scope;
        $txn->lookup( 'is_base' => 1 );
    };
    ok(!$@, 'ok');
}

sub t_61_driver_isnot_base_driver : Tests(1) {
    eval {
        my $txn = mock->txn_scope;
        $txn->lookup( 'isnot_base' => 1 );
    };
    like $@, qr/'isnot_base' has driver is not same base_driver/;
}

1;

