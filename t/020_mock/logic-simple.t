use t::Utils;
use Test::More tests => 20;
use Mock::Logic::Simple;

my $mock = Mock::Logic::Simple->new;

do {
    my($ret1) = $mock->get( user => 'yappo' );
    ok(Mock::Logic::Simple::user->can('id'));
    isa_ok $ret1, 'Mock::Logic::Simple::user';
    is $ret1->name, 'Osawa';
    
    my($ret2) = $mock->get( user => 'lopnor' );
    isa_ok $ret2, 'Mock::Logic::Simple::user';
    is $ret2->name, 'Danjou';
    
    my $ret3 = $mock->set( user => +{
        id   => 'soozy',
        name => 'Souji',
    });
    isa_ok $ret3, 'Mock::Logic::Simple::user';
    is $ret3->id, 'soozy';
    is $ret3->name, 'Souji';
    
    ok $mock->delete( user => 'ok' );
    ok !$mock->delete( user => 'ng' );
};

do {
    my($ret1) = $mock->get( barerow => 'yappo' );
    ok(!Mock::Logic::Simple::barerow->can('id'));
    isa_ok $ret1, 'HASH';
    is $ret1->{name}, 'Osawa';
    
    my($ret2) = $mock->get( barerow => 'lopnor' );
    isa_ok $ret2, 'HASH';
    is $ret2->{name}, 'Danjou';
    
    my $ret3 = $mock->set( barerow => +{
        id   => 'soozy',
        name => 'Souji',
    });
    isa_ok $ret3, 'HASH';
    is $ret3->{id}, 'soozy';
    is $ret3->{name}, 'Souji';
    
    ok $mock->delete( barerow => 'ok' );
    ok !$mock->delete( barerow => 'ng' );
};
