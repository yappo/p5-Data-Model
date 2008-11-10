use t::Utils;
use Test::More tests => 9;
use Mock::Logic::Simple;

my $mock = Mock::Logic::Simple->new;
my($ret1) = $mock->get( user => 'yappo' );
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
