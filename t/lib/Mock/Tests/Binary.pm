package Mock::Tests::Binary;
use t::Utils;
use base 'Test::Class';
use Mock::Tests;
use Test::More;

my $bin1 = pack 'C*', qw( 10 2 43 0 9 84 45 255 );
sub t_01_set : Tests(4) {
    my $set = mock->set( model => 1 => { data => $bin1 } );
    isa_ok $set, mock_class."::model";
    is $set->id, 1, 'id';
    is $set->data, $bin1, 'binary data';

    use bytes;
    is bytes::length($set->data), 8, 'length';
}

sub t_02_get : Tests(4) {
    my($get) = mock->get( model => 1 );
    isa_ok $get, mock_class."::model";
    is $get->id, 1, 'id';
    is $get->data, $bin1, 'binary data';

    use bytes;
    is bytes::length($get->data), 8, 'length';
}

1;

