package Mock::Tests::DriverMemcached;
use t::Utils;
use base 'Test::Class';
use Mock::Tests;
use Test::More;

sub t_001_shimple_set : Tests {
    my $set1 = mock->set( simple => '1', { name => 'NAME' });
    ok($set1, 'set ok');
    is $set1->id, 1, 'id = 1';
    is $set1->name, 'NAME', 'name = NAME';

    my $set2 = mock->set( simple => 'id2', { name => 'yappo' });
    ok($set2, 'set ok');
    is $set2->id, 'id2', 'id = id2';
    is $set2->name, 'yappo', 'name = yappo';
}

sub t_002_shimple_get : Tests {
    my($get1) = mock->get( simple => '1');
    ok($get1, 'get ok');
    is $get1->id, 1, 'id = 1';
    is $get1->name, 'NAME', 'name = NAME';

    my($get2) = mock->get( simple => 'id2' );
    ok($get2, 'get ok');
    is $get2->id, 'id2', 'id = id2';
    is $get2->name, 'yappo', 'name = yappo';
}

sub t_003_shimple_update : Tests {
    my($get1) = mock->get( simple => '1');
    $get1->name('NAME is Yappo');
    ok($get1->update, 'update ok');

    my($get2) = mock->get( simple => 1 );
    ok($get2, 'get ok');
    is $get2->name, 'NAME is Yappo', 'name ok';
}

sub t_004_shimple_delete : Tests {
    ok(mock->delete( simple => 'id2'), 'delete ok');
    ok(!mock->get( simple => 'id2' ), 'deleted data');
    ok(!mock->delete( simple => 'id2'), 'do not delete data');

    my($get1) = mock->get( simple => '1');
    ok($get1, 'id 1 is not daelete data');
}

sub t_005_shimple_update_key : Tests {
    my($get1) = mock->get( simple => '1');
    $get1->id('ID');
    $get1->update;

    ok(!mock->get( simple => 1 ), 'id 1 is change key');
    my($get2) = mock->get( simple => 'ID' );
    ok($get2, 'get ok');
    is $get2->name, 'NAME is Yappo', 'name ok';
}

sub t_006_shimple_replace : Tests {
    my($ret) = mock->replace( simple => 'ID' => { name => 'replaichament' } );
    is $ret->id, 'ID', 'id ok';
    is $ret->name, 'replaichament', 'name ok';

    my($get) = mock->get( simple => 'ID' );
    is $get->id, 'ID', 'id ok';
    is $get->name, 'replaichament', 'name ok';
}

sub t_007_shimple_duble_insert : Tests {
    my($ret) = mock->set( simple => 'ID' => { name => 're-insert' } );
    ok(!$ret, 'set fail');
}

sub t_008_prepere : Tests {
    ok(mock->set( simple => 101 => { name => 'yappo' } ));
    ok(mock->set( simple => 102 => { name => 'osawa' } ));
    ok(mock->set( simple => 103 => { name => 'kazuhiro' } ));
}

sub t_009_lookup : Tests {
    my $lookup = mock->lookup( simple => 102 );
    isa_ok $lookup, mock_class."::simple";
    is $lookup->id, 102, 'id';
    is $lookup->name, 'osawa', 'name';
}

sub t_010_lookup_multi : Tests {
    my @lookup = mock->lookup_multi( simple => [ 103, 101, 102 ] );

    isa_ok $lookup[0], mock_class."::simple";
    is $lookup[0]->id, 103, 'id';
    is $lookup[0]->name, 'kazuhiro', 'name';
    isa_ok $lookup[1], mock_class."::simple";
    is $lookup[1]->id, 101, 'id';
    is $lookup[1]->name, 'yappo', 'name';
    isa_ok $lookup[2], mock_class."::simple";
    is $lookup[2]->id, 102, 'id';
    is $lookup[2]->name, 'osawa', 'name';
}


sub t_101_multi_keys_set : Tests {
    eval {
        mock->set( multi_keys => 'id1' );
    };
    like $@, qr/The number of key is wrong/, 'keymissmatch';
    eval {
        mock->set( multi_keys => [qw/ id1 id2 /] );
    };
    like $@, qr/The number of key is wrong/, 'keymissmatch';

    my $set1 = mock->set( multi_keys => [qw/ id1 id2 id3 /] );
    ok($set1, 'set ok');
    is $set1->key1, 'id1', 'key1';
    is $set1->key2, 'id2', 'key2';
    is $set1->key3, 'id3', 'key3';
}

sub t_102_multi_keys_get : Tests {
    eval {
        mock->get( multi_keys => 'id1' );
    };
    like $@, qr/The number of key is wrong/, 'keymissmatch';
    eval {
        mock->get( multi_keys => [qw/ id1 id2 /] );
    };
    like $@, qr/The number of key is wrong/, 'keymissmatch';

    my($get1) = mock->get( multi_keys => [qw/ id1 id2 id3 /] );
    ok($get1, 'set ok');
    is $get1->key1, 'id1', 'key1';
    is $get1->key2, 'id2', 'key2';
    is $get1->key3, 'id3', 'key3';
}

sub t_103_prepere : Tests {
    ok(mock->set( multi_keys => [qw/ k1 k2 k3 /] ));
    ok(mock->set( multi_keys => [qw/ e1 e2 e3 /] ));
}

sub t_104_lookup : Tests {
    my $lookup = mock->lookup( multi_keys => [qw/ k1 k2 k3/] );
    ok($lookup, 'set ok');
    is $lookup->key1, 'k1', 'key1';
    is $lookup->key2, 'k2', 'key2';
    is $lookup->key3, 'k3', 'key3';
}

sub t_105_lookup_multi : Tests {
    my @lookup = mock->lookup_multi( multi_keys => [ [qw/ e1 e2 e3 /], [qw/ a s d /], [qw/ k1 k2 k3/] ] );
    ok($lookup[0], 'set ok');
    is $lookup[0]->key1, 'e1', 'key1';
    is $lookup[0]->key2, 'e2', 'key2';
    is $lookup[0]->key3, 'e3', 'key3';
    ok($lookup[2], 'set ok');
    is $lookup[2]->key1, 'k1', 'key1';
    is $lookup[2]->key2, 'k2', 'key2';
    is $lookup[2]->key3, 'k3', 'key3';
}

sub t_201_multi_keys_columns_set : Tests {
    my $set1 = mock->set(
        multi_keys_columns => [qw/ ya pp o /],
        {
            name     => 'osawa',
            nickname => 'yappo'
        }
    );
    ok($set1, 'set ok');
    is $set1->key1, 'ya', 'key1';
    is $set1->key2, 'pp', 'key2';
    is $set1->key3, 'o', 'key3';
    is $set1->name, 'osawa', 'name';
    is $set1->nickname, 'yappo', 'nickname';
}

sub t_202_multi_keys_columns_get : Tests {
    my($get1) = mock->get( multi_keys_columns => [qw/ ya pp o /] );
    ok($get1, 'set ok');
    is $get1->key1, 'ya', 'key1';
    is $get1->key2, 'pp', 'key2';
    is $get1->key3, 'o', 'key3';
    is $get1->name, 'osawa', 'name';
    is $get1->nickname, 'yappo', 'nickname';
}


# with rename
sub t_001_shimple_set_rename : Tests {
    my $set1 = mock->set( simple_rename => '1', { name => 'NAME' });
    ok($set1, 'set ok');
    is $set1->id, 1, 'id = 1';
    is $set1->name, 'NAME', 'name = NAME';

    my $set2 = mock->set( simple_rename => 'id2', { name => 'yappo' });
    ok($set2, 'set ok');
    is $set2->id, 'id2', 'id = id2';
    is $set2->name, 'yappo', 'name = yappo';
}

sub t_002_shimple_get_rename : Tests {
    my($get1) = mock->get( simple_rename => '1');
    ok($get1, 'get ok');
    is $get1->id, 1, 'id = 1';
    is $get1->name, 'NAME', 'name = NAME';

    my($get2) = mock->get( simple_rename => 'id2' );
    ok($get2, 'get ok');
    is $get2->id, 'id2', 'id = id2';
    is $get2->name, 'yappo', 'name = yappo';
}

sub t_003_shimple_update_rename : Tests {
    my($get1) = mock->get( simple_rename => '1');
    $get1->name('NAME is Yappo');
    ok($get1->update, 'update ok');

    my($get2) = mock->get( simple_rename => 1 );
    ok($get2, 'get ok');
    is $get2->name, 'NAME is Yappo', 'name ok';
}

sub t_004_shimple_delete_rename : Tests {
    ok(mock->delete( simple_rename => 'id2'), 'delete ok');
    ok(!mock->get( simple_rename => 'id2' ), 'deleted data');
    ok(!mock->delete( simple_rename => 'id2'), 'do not delete data');

    my($get1) = mock->get( simple_rename => '1');
    ok($get1, 'id 1 is not daelete data');
}

sub t_005_shimple_update_key_rename : Tests {
    my($get1) = mock->get( simple_rename => '1');
    $get1->id('ID');
    $get1->update;

    ok(!mock->get( simple_rename => 1 ), 'id 1 is change key');
    my($get2) = mock->get( simple_rename => 'ID' );
    ok($get2, 'get ok');
    is $get2->name, 'NAME is Yappo', 'name ok';
}

sub t_006_shimple_replace_rename : Tests {
    my($ret) = mock->replace( simple_rename => 'ID' => { name => 'replaichament' } );
    is $ret->id, 'ID', 'id ok';
    is $ret->name, 'replaichament', 'name ok';

    my($get) = mock->get( simple_rename => 'ID' );
    is $get->id, 'ID', 'id ok';
    is $get->name, 'replaichament', 'name ok';
}

sub t_007_shimple_duble_insert_rename : Tests {
    my($ret) = mock->set( simple_rename => 'ID' => { name => 're-insert' } );
    ok(!$ret, 'set fail');
}

sub t_008_prepere_rename : Tests {
    ok(mock->set( simple_rename => 101 => { name => 'yappo' } ));
    ok(mock->set( simple_rename => 102 => { name => 'osawa' } ));
    ok(mock->set( simple_rename => 103 => { name => 'kazuhiro' } ));
}

sub t_009_lookup_rename : Tests {
    my $lookup = mock->lookup( simple_rename => 102 );
    isa_ok $lookup, mock_class."::simple_rename";
    is $lookup->id, 102, 'id';
    is $lookup->name, 'osawa', 'name';
}

sub t_010_lookup_multi_rename : Tests {
    my @lookup = mock->lookup_multi( simple_rename => [ 103, 101, 102 ] );

    isa_ok $lookup[0], mock_class."::simple_rename";
    is $lookup[0]->id, 103, 'id';
    is $lookup[0]->name, 'kazuhiro', 'name';
    isa_ok $lookup[1], mock_class."::simple_rename";
    is $lookup[1]->id, 101, 'id';
    is $lookup[1]->name, 'yappo', 'name';
    isa_ok $lookup[2], mock_class."::simple_rename";
    is $lookup[2]->id, 102, 'id';
    is $lookup[2]->name, 'osawa', 'name';
}


sub t_101_multi_keys_set_rename : Tests {
    eval {
        mock->set( multi_keys_rename => 'id1' );
    };
    like $@, qr/The number of key is wrong/, 'keymissmatch';
    eval {
        mock->set( multi_keys_rename => [qw/ id1 id2 /] );
    };
    like $@, qr/The number of key is wrong/, 'keymissmatch';

    my $set1 = mock->set( multi_keys_rename => [qw/ id1 id2 id3 /] );
    ok($set1, 'set ok');
    is $set1->key1, 'id1', 'key1';
    is $set1->key2, 'id2', 'key2';
    is $set1->key3, 'id3', 'key3';
}

sub t_102_multi_keys_get_rename : Tests {
    eval {
        mock->get( multi_keys_rename => 'id1' );
    };
    like $@, qr/The number of key is wrong/, 'keymissmatch';
    eval {
        mock->get( multi_keys_rename => [qw/ id1 id2 /] );
    };
    like $@, qr/The number of key is wrong/, 'keymissmatch';

    my($get1) = mock->get( multi_keys_rename => [qw/ id1 id2 id3 /] );
    ok($get1, 'set ok');
    is $get1->key1, 'id1', 'key1';
    is $get1->key2, 'id2', 'key2';
    is $get1->key3, 'id3', 'key3';
}

sub t_103_prepere_rename : Tests {
    ok(mock->set( multi_keys_rename => [qw/ k1 k2 k3 /] ));
    ok(mock->set( multi_keys_rename => [qw/ e1 e2 e3 /] ));
}

sub t_104_lookup_rename : Tests {
    my $lookup = mock->lookup( multi_keys_rename => [qw/ k1 k2 k3/] );
    ok($lookup, 'set ok');
    is $lookup->key1, 'k1', 'key1';
    is $lookup->key2, 'k2', 'key2';
    is $lookup->key3, 'k3', 'key3';
}

sub t_105_lookup_multi_rename : Tests {
    my @lookup = mock->lookup_multi( multi_keys_rename => [ [qw/ e1 e2 e3 /], [qw/ a s d /], [qw/ k1 k2 k3/] ] );
    ok($lookup[0], 'set ok');
    is $lookup[0]->key1, 'e1', 'key1';
    is $lookup[0]->key2, 'e2', 'key2';
    is $lookup[0]->key3, 'e3', 'key3';
    ok($lookup[2], 'set ok');
    is $lookup[2]->key1, 'k1', 'key1';
    is $lookup[2]->key2, 'k2', 'key2';
    is $lookup[2]->key3, 'k3', 'key3';
}

sub t_201_multi_keys_columns_set_rename : Tests {
    my $set1 = mock->set(
        multi_keys_columns_rename => [qw/ ya pp o /],
        {
            name     => 'osawa',
            nickname => 'yappo'
        }
    );
    ok($set1, 'set ok');
    is $set1->key1, 'ya', 'key1';
    is $set1->key2, 'pp', 'key2';
    is $set1->key3, 'o', 'key3';
    is $set1->name, 'osawa', 'name';
    is $set1->nickname, 'yappo', 'nickname';
}

sub t_202_multi_keys_columns_get_rename : Tests {
    my($get1) = mock->get( multi_keys_columns_rename => [qw/ ya pp o /] );
    ok($get1, 'set ok');
    is $get1->key1, 'ya', 'key1';
    is $get1->key2, 'pp', 'key2';
    is $get1->key3, 'o', 'key3';
    is $get1->name, 'osawa', 'name';
    is $get1->nickname, 'yappo', 'nickname';
}


1;
