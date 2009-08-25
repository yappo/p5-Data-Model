package Mock::Tests::Iterator;
use t::Utils;
use base 'Test::Class';
use Mock::Tests;
use Test::More;

sub t : Tests {
    mock->set( user => '1foo' );
    mock->set( user => '2bar' );
    mock->set( user => '3baz' );


    my $itr = mock->get( user => 1 );
    isa_ok($itr, 'Data::Model::Iterator::Empty');
    ok(!$itr, 'record not found');
    ok(!$itr->has_next, 'next record not found');

    $itr = mock->get( 'user' => { order => [ +{ foo => 'ASC' } ] } );
    isa_ok($itr, 'Data::Model::Iterator');
    my @exps = qw( 1foo 2bar 3baz );
    ok($itr->has_next, 'next record found');
    while (<$itr>) {
        my $v = shift @exps;
        is($_->foo, $v, "foo is $v");
    }
    ok(!$itr->has_next, 'next record not found');
}

1;

