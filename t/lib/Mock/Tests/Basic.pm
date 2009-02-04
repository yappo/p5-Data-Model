package Mock::Tests::Basic;
use t::Utils;
use base 'Test::Class';
use Mock::Tests;
use Test::More;

sub t_01_basic : Tests {
    my $ret1 = mock->set( user => 'yappo', { name => 'Kazuhiro Osawa' } );
    isa_ok $ret1, mock_class."::user";
    is $ret1->id, 'yappo';
    is $ret1->name, 'Kazuhiro Osawa';

    my($ret2) = mock->get( user => 'yappo' );
    isa_ok $ret2, mock_class."::user";
    is $ret2->id, 'yappo';
    is $ret2->name, 'Kazuhiro Osawa';

    ok mock->delete( user => 'yappo' ), 'delete ok';
    ($ret2) = mock->get( user => 'yappo' );
    ok !$ret2, 'get error';
    ok !mock->delete( user => 'yappo' ), 'delete error';
}

sub t_02_insert_bookmark_user : Tests {
    my $ret1 = mock->set( bookmark_user => [qw/ 1 yappo /] );
    isa_ok $ret1, mock_class."::bookmark_user";
    is $ret1->bookmark_id, 1, 'bookmark_id';
    is $ret1->user_id, 'yappo';

    $ret1 = mock->set( bookmark_user => [qw/ 1 lopnor /] );
    is $ret1->bookmark_id, 1;
    is $ret1->user_id, 'lopnor';

    $ret1 = mock->set( bookmark_user => [qw/ 2 yappo /] );
    is $ret1->bookmark_id, 2;
    is $ret1->user_id, 'yappo';

    $ret1 = mock->set( bookmark_user => [qw/ 2 lopnor /] );
    is $ret1->bookmark_id, 2;
    is $ret1->user_id, 'lopnor';
}

sub t_03_get : Tests {
    my($ret2) = mock->get( bookmark_user => [qw/ 1 yappo /] );
    isa_ok $ret2, mock_class."::bookmark_user";
    is $ret2->bookmark_id, 1;
    is $ret2->user_id, 'yappo';
}
        
sub t_03_order : Tests {
    my($ret3) = mock->get( bookmark_user => '1', { order => [ { user_id => 'DESC' } ] } );
    isa_ok $ret3, mock_class."::bookmark_user";
    is $ret3->bookmark_id, 1;
    is $ret3->user_id, 'yappo';
}

sub t_03_index : Tests {
    my($ret4) = mock->get( bookmark_user => {
        index => { user_id => 'lopnor' },
        order => [{ bookmark_id => 'DESC' }],
    });
    isa_ok $ret4, mock_class."::bookmark_user";
    is $ret4->bookmark_id, 2;
    is $ret4->user_id, 'lopnor';
}
    
sub t_04_delete : Tests {
    ok mock->delete( bookmark_user => [qw/ 1 yappo /] ), 'delete bookmark_user';
    ok !mock->get( bookmark_user => [qw/ 1 yappo /] ), 'get error bookmark_user';
    ok !mock->delete( bookmark_user => [qw/ 1 yappo /] ), 'delete error bookmark_user';
}

sub t_05_select_all_iterator : Tests(5) {
    my $itr = mock->get('bookmark_user');
    isa_ok $itr, 'Data::Model::Iterator';
    my $i = 0;
    while (my $row = $itr->next) {
        $i++;
        isa_ok $row, mock_class."::bookmark_user";
    }
    is $i, 3;
}

sub t_05_select_all_iterator_with_reset : Tests(8) {
    my $itr = mock->get('bookmark_user');
    isa_ok $itr, 'Data::Model::Iterator';
    my $i = 0;
    while (my $row = $itr->next) {
        $i++;
        isa_ok $row, mock_class."::bookmark_user";
    }
    $itr->reset;
    while (my $row = $itr->next) {
        $i++;
        isa_ok $row, mock_class."::bookmark_user";
    }
    is $i, 6;
}

sub t_05_select_all_iterator_limit : Tests(4) {
    my $itr = mock->get('bookmark_user', { limit => 2 });
    isa_ok $itr, 'Data::Model::Iterator';
    my $i = 0;
    while (my $row = $itr->next) {
        $i++;
        isa_ok $row, mock_class."::bookmark_user";
    }
    is $i, 2;
}

sub t_05_select_all_iterator_limit_offset : Tests(3) {
    my $itr = mock->get('bookmark_user', { limit => 1, offset => 2 });
    isa_ok $itr, 'Data::Model::Iterator';
    my $i = 0;
    while (my $row = $itr->next) {
        $i++;
        isa_ok $row, mock_class."::bookmark_user";
    }
    is $i, 1;
}

sub t_06_update : Tests {
    my($set) = mock->set( user => 'yappo' => { name => '-' } );
    is $set->name, '-', 'is -';
    my($obj) = mock->get( user => 'yappo' );

    $obj->name('Kazuhiro Osawa');
    $obj->update;
    my($obj2) = mock->get( user => 'yappo' );
    is $obj2->name, 'Kazuhiro Osawa', 'is Kazuhiro Osawa';

    $obj->name('Kazuhiro');
    mock->set($obj);
    my($obj3) = mock->get( user => 'yappo' );
    is $obj3->name, 'Kazuhiro', 'is Kazuhiro';

    $obj->name('Kazuhiro Osawa');
    mock->replace($obj);
    my($obj4) = mock->get( user => 'yappo' );
    is $obj4->name, 'Kazuhiro Osawa', 'is Kazuhiro Osawa';


    $obj->name('Osawa');
    mock->replace($obj);
    my($obj5) = mock->get( user => 'yappo' );
    is $obj5->name, 'Osawa', 'is Osawa';
}

sub t_06_update_2ndidx : Tests {
    my $set1 = mock->set( bookmark_user => [qw/ 10 jyappo /] );
    isa_ok $set1, mock_class."::bookmark_user";
    my $set2 = mock->set( bookmark_user => [qw/ 11 jyappo /] );
    isa_ok $set2, mock_class."::bookmark_user";

    my $row;
    my $it = mock->get( bookmark_user => { index => { user_id => 'jyappo' }, order => [{ bookmark_id => 'ASC' }] } );
    $row = $it->next;
    isa_ok $row, mock_class."::bookmark_user";
    is $row->bookmark_id, 10, '10 jyappo';
    is $row->user_id, 'jyappo', '10 jyappo';
    $row = $it->next;
    isa_ok $row, mock_class."::bookmark_user";
    is $row->bookmark_id, 11, '11 jyappo';
    is $row->user_id, 'jyappo', '11 jyappo';
    ok !$it->next;

    $row->user_id('iyappo');
    $row->update;

    $it = mock->get( bookmark_user => { index => { user_id => 'jyappo' }, order => [{ bookmark_id => 'ASC' }] } );
    $row = $it->next;
    isa_ok $row, mock_class."::bookmark_user";
    is $row->bookmark_id, 10, '10 jyappo';
    is $row->user_id, 'jyappo', '10 jyappo';
    ok !$it->next;

    $it = mock->get( bookmark_user => { index => { user_id => 'iyappo' }, order => [{ bookmark_id => 'ASC' }] } );
    $row = $it->next;
    isa_ok $row, mock_class."::bookmark_user";
    is $row->bookmark_id, 11, '11 iyappo';
    is $row->user_id, 'iyappo', '11 iyappo';
    ok !$it->next;
}

sub t_07_replace : Tests {
    my $set1  = mock->set( user => 'yappologs' => { name => 'blog' } );
    is $set1->name, 'blog', 'is blog';
    my($obj1) = mock->get( user => 'yappologs' );
    is $obj1->name, 'blog', 'is blog';

    my $set2  = mock->replace( user => 'yappologs' => { name => "yappo's blog" } );
    is $set2->name, "yappo's blog", "is yappo's blog";
    my($obj2) = mock->get( user => 'yappologs' );
    is $obj2->name, "yappo's blog", "is yappo's blog";
}

sub t_08_autoincrement : Tests {
    my $set1 = mock->set( bookmark => { url => 'url1' });
    is $set1->id, 1, 'set id1';
    is $set1->url, 'url1';

    my $set2 = mock->set( bookmark => { url => 'url2' });
    is $set2->id, 2, 'set id2';
    is $set2->url, 'url2';

    my $set3 = mock->set( bookmark => { url => 'url3' });
    is $set3->id, 3, 'set id3';
    is $set3->url, 'url3';


    my($key1) = mock->get( bookmark => 1 );
    is $key1->id, 1, 'key id1';
    is $key1->url, 'url1';

    my($key2) = mock->get( bookmark => 2 );
    is $key2->id, 2, 'key id2';
    is $key2->url, 'url2';

    my($key3) = mock->get( bookmark => 3 );
    is $key3->id, 3, 'key id3';
    is $key3->url, 'url3';


    my($idx1) = mock->get( bookmark => { index => { url => 'url1' } } );
    is $idx1->id, 1, 'idx id1';
    is $idx1->url, 'url1';

    my($idx2) = mock->get( bookmark => { index => { url => 'url2' } } );
    is $idx2->id, 2, 'idx id2';
    is $idx2->url, 'url2';

    my($idx3) = mock->get( bookmark => { index => { url => 'url3' } } );
    is $idx3->id, 3, 'idx id3';
    is $idx3->url, 'url3';
}

sub t_09_get_delete : Tests {
    my $set = mock->set( user => 'select-delete', { name => 'Kazuhiro Osawa' } );
    isa_ok $set, mock_class."::user";

    my($get) = mock->get( user => 'select-delete' );
    isa_ok $get, mock_class."::user";
    ok($get->delete, 'delete by row');

    ok(!mock->get( user => 'select-delete' ));
}

sub t_10_direct_update : Tests {
    my $set1 = mock->set( user => 'direct_update-1', { name => 'direct_update 1' } );
    isa_ok $set1, mock_class."::user";
    my $set2 = mock->set( user => 'direct_update-2', { name => 'direct_update 2' } );
    isa_ok $set2, mock_class."::user";

    my($get1) = mock->get( user => 'direct_update-1' );
    isa_ok $get1, mock_class."::user";
    is $get1->id, 'direct_update-1';
    is $get1->name, 'direct_update 1';
    my($get2) = mock->get( user => 'direct_update-2' );
    isa_ok $get2, mock_class."::user";
    is $get2->id, 'direct_update-2';
    is $get2->name, 'direct_update 2';

    ok mock->update(
        user => 'direct_update-1',
        undef, +{
            name => 'updated direct_update 1',
        },
    ), 'update 1';
    my($get3) = mock->get( user => 'direct_update-1' );
    isa_ok $get3, mock_class."::user";
    is $get3->id, 'direct_update-1';
    is $get3->name, 'updated direct_update 1';

    ok mock->update(
        user => ['direct_update-1'],
        undef, +{
            name => 'updated 2 direct_update 1',
        },
    ), 'update 2';
    my($get4) = mock->get( user => 'direct_update-1' );
    isa_ok $get4, mock_class."::user";
    is $get4->id, 'direct_update-1';
    is $get4->name, 'updated 2 direct_update 1';

    my($get5) = mock->get( user => 'direct_update-2' );
    isa_ok $get5, mock_class."::user";
    is $get5->id, 'direct_update-2';
    is $get5->name, 'direct_update 2';


    ok mock->update(
        user => +{
            where => [
                name => { LIKE => '%2' },
            ],
        }, +{
            name => 'updated direct_update 2',
        },
    ), 'update 3';
    my($get6) = mock->get( user => 'direct_update-1' );
    isa_ok $get6, mock_class."::user";
    is $get6->id, 'direct_update-1';
    is $get6->name, 'updated 2 direct_update 1';
    my($get7) = mock->get( user => 'direct_update-2' );
    isa_ok $get7, mock_class."::user";
    is $get7->id, 'direct_update-2';
    is $get7->name, 'updated direct_update 2';


    ok mock->update(
        user => ['direct_update-1'],
        undef, +{
            id   => 'direct_update-3',
            name => 'direct_update 3',
        },
    ), 'update 4';
    ok(!mock->get( user => 'direct_update-1' ));
    my($get8) = mock->get( user => 'direct_update-3' );
    isa_ok $get8, mock_class."::user";
    is $get8->id, 'direct_update-3';
    is $get8->name, 'direct_update 3';
    my($get9) = mock->get( user => 'direct_update-2' );
    isa_ok $get9, mock_class."::user";
    is $get9->id, 'direct_update-2';
    is $get9->name, 'updated direct_update 2';
}

sub t_11_obj_delete : Tests {
    my $set = mock->set( user => 'obj-delete', { name => 'Kazuhiro Osawa' } );
    isa_ok $set, mock_class."::user";

    my($get) = mock->get( user => 'obj-delete' );
    isa_ok $get, mock_class."::user";
    ok(mock->delete($get), 'mock->delete( $obj )');

    ok(!mock->get( user => 'obj-delete' ));
}

sub t_12_lookup : Tests {
    my $lookup = mock->lookup( user => 'yappo' );
    isa_ok $lookup, mock_class."::user";
    is $lookup->id, 'yappo', 'id is yappo';
    is $lookup->name, 'Osawa', 'name is Osawa';
}

1;
