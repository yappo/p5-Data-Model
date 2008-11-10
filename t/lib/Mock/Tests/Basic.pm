package Mock::Tests::Basic;
use t::Utils;
use Test::More;

sub tests { 30 }

sub run {
    my($class, $mock) = @_;
    my $mock_class = ref($mock);

    do {
        my $ret1 = $mock->set( user => 'yappo', { name => 'Kazuhiro Osawa' } );
        isa_ok $ret1, "$mock_class\::user";
        is $ret1->id, 'yappo';
        is $ret1->name, 'Kazuhiro Osawa';

        my($ret2) = $mock->get( user => 'yappo' );
        isa_ok $ret2, "$mock_class\::user";
        is $ret2->id, 'yappo';
        is $ret2->name, 'Kazuhiro Osawa';

        ok $mock->delete( user => 'yappo' ), 'delete ok';
        ($ret2) = $mock->get( user => 'yappo' );
        ok !$ret2, 'get error';
        ok !$mock->delete( user => 'yappo' ), 'delete error';
    };

    do {
        my $ret1 = $mock->set( bookmark_user => [qw/ 1 yappo /] );
        isa_ok $ret1, "$mock_class\::bookmark_user";
        is $ret1->bookmark_id, 1, 'bookmark_id';
        is $ret1->user_id, 'yappo';

        $ret1 = $mock->set( bookmark_user => [qw/ 1 lopnor /] );
        is $ret1->bookmark_id, 1;
        is $ret1->user_id, 'lopnor';

        $ret1 = $mock->set( bookmark_user => [qw/ 2 yappo /] );
        is $ret1->bookmark_id, 2;
        is $ret1->user_id, 'yappo';

        $ret1 = $mock->set( bookmark_user => [qw/ 2 lopnor /] );
        is $ret1->bookmark_id, 2;
        is $ret1->user_id, 'lopnor';
        
        
        my($ret2) = $mock->get( bookmark_user => [qw/ 1 yappo /] );
        isa_ok $ret2, "$mock_class\::bookmark_user";
        is $ret2->bookmark_id, 1;
        is $ret2->user_id, 'yappo';
        
        my($ret3) = $mock->get( bookmark_user => '1', { order => [ { user_id => 'DESC' } ] } );
        isa_ok $ret3, "$mock_class\::bookmark_user";
        is $ret3->bookmark_id, 1;
        is $ret3->user_id, 'yappo';

        my($ret4) = $mock->get( bookmark_user => {
            index => { user_id => 'yappo' },
        });
        isa_ok $ret4, "$mock_class\::bookmark_user";
        is $ret4->bookmark_id, 1;
        is $ret4->user_id, 'yappo';
        
        ok $mock->delete( bookmark_user => [qw/ 1 yappo /] ), 'delete bookmark_user';
        ok !$mock->get( bookmark_user => [qw/ 1 yappo /] ), 'get error bookmark_user';
        ok !$mock->delete( bookmark_user => [qw/ 1 yappo /] ), 'delete error bookmark_user';
    };
}

1;
