package Mock::Tests::ForCache;
use t::Utils;
use base 'Test::Class';
use Mock::Tests;
use Test::More;

sub t_001_insert : Tests {
    ok(mock->set( user => 'id1', { name => 'name1' } ));
    ok(mock->set( user => 'id2', { name => 'name2' } ));
    ok(mock->set( user => 'id3', { name => 'name3' } ));
    ok(mock->set( user => 'id4', { name => 'name4' } ));
    ok(mock->set( user => 'id5', { name => 'name5' } ));
    ok(mock->set( user => 'id6', { name => 'name6' } ));
    ok(mock->set( user => 'id7', { name => 'name7' } ));
    ok(mock->set( user => 'id8', { name => 'name8' } ));
}

sub t_002_lookup_delete_lookup : Tests {
    my $get = mock->lookup( user => 'id3' );
    ok($get, 'lookup ok');
    is $get->id, 'id3', 'id ok';
    is $get->name, 'name3', 'name ok';

    ok($get->delete, 'delete ok');

    ok(!mock->lookup( user => 'id3' ), 'id3 is deleted');;
}

sub t_003_lookup_update_lookup : Tests {
    my $get = mock->lookup( user => 'id5' );
    ok($get, 'lookup ok');
    is $get->id, 'id5', 'id ok';
    is $get->name, 'name5', 'name ok';

    $get->name('name5 rename');
    ok($get->update, 'update ok');

    $get = mock->lookup( user => 'id5' );
    ok($get, 'lookup ok');
    is $get->id, 'id5', 'id ok';
    is $get->name, 'name5 rename', 'name ok';
}

sub t_004_lookup_multi_directdelete_lookup : Tests {
    my @get = mock->lookup_multi(
        user => [qw/ id7 id2 /]
    );
    is scalar(@get), 2, 'get 2 record 004';

    ok($get[0], 'record 1 ok');
    is $get[0]->id, 'id7', 'id 1';
    is $get[0]->name, 'name7', 'name 1';
    ok($get[1], 'record 2 ok');
    is $get[1]->id, 'id2', 'id 2';
    is $get[1]->name, 'name2', 'name 2';

    ok mock->delete(
        user => +{
            where => [
                id => { IN => [qw/ id7 id2 /] },
            ],
        },
    ), 'direct delete ok';

    @get = mock->lookup_multi(
        user => [qw/ id7 id2 /]
    );
    is scalar(@get), 2, 'get 2 record';
    ok(!$get[0], 'record 1 is deleted');
    ok(!$get[1], 'record 2 is deleted');
}

sub t_005_lookup_multi_directupdate_lookup : Tests {
    my @get = mock->lookup_multi(
        user => [qw/ id4 id6 /]
    );
    is scalar(@get), 2, 'get 2 record';

    ok($get[0], 'record 1 ok');
    is $get[0]->id, 'id4', 'id 1';
    is $get[0]->name, 'name4', 'name 1';
    ok($get[1], 'record 2 ok');
    is $get[1]->id, 'id6', 'id 2';
    is $get[1]->name, 'name6', 'name 2';

    ok mock->update(
        user => +{
            where => [
                id => { IN => [qw/ id6 id4 /] },
            ],
        },
        { name => 'direct update' },
    ), 'direct update ok';

    @get = mock->lookup_multi(
        user => [qw/ id4 id6 /]
    );
    is scalar(@get), 2, 'get 2 record';

    ok($get[0], 'record 1 ok');
    is $get[0]->id, 'id4', 'id 1';
    is $get[0]->name, 'direct update', 'name 1';
    ok($get[1], 'record 2 ok');
    is $get[1]->id, 'id6', 'id 2';
    is $get[1]->name, 'direct update', 'name 2';
}

sub t_006_lookup_replace_lookup : Tests {
    my $get = mock->lookup( user => 'id8' );
    ok($get, 'lookup ok');
    is $get->id, 'id8', 'id ok';
    is $get->name, 'name8', 'name ok';

    ok(mock->replace( user => 'id8' => { name => "replace" } ), 'replace ok');

    $get = mock->lookup( user => 'id8' );
    ok($get, 'lookup ok');
    is $get->id, 'id8', 'id ok';
    is $get->name, 'replace', 'name ok';
}

sub t_100_driver_change : Tests(1) {
    my $driver = mock->get_driver('user');
    return ok(1) unless $driver->{fallback};
    mock->set_driver('user',  $driver->{fallback});
    ok(1);
}

sub t_101_check_fallback_driver : Tests {
    my @get = mock->lookup_multi(
        user => [qw/ id1 id2 id3 id4 id5 id6 id7 id8 /]
    );
    is scalar(@get), 8, 'get 8 record';

    ok($get[0], 'record 1 ok');
    is $get[0]->id, 'id1', 'id 1 ok';
    is $get[0]->name, 'name1', 'name 1 ok';

    ok(!$get[1], 'record 2 deleted');
    ok(!$get[2], 'record 3 deleted');

    ok($get[3], 'record 4 ok');
    is $get[3]->id, 'id4', 'id 4 ok';
    is $get[3]->name, 'direct update', 'name 4 ok';

    ok($get[4], 'record 5 ok');
    is $get[4]->id, 'id5', 'id 5 ok';
    is $get[4]->name, 'name5 rename', 'name 5 ok';

    ok($get[5], 'record 6 ok');
    is $get[5]->id, 'id6', 'id 6 ok';
    is $get[5]->name, 'direct update', 'name 6 ok';

    ok(!$get[6], 'record 7 deleted');

    ok($get[7], 'record 8 ok');
    is $get[7]->id, 'id8', 'id 8 ok';
    is $get[7]->name, 'replace', 'name 8 ok';

}


1;

