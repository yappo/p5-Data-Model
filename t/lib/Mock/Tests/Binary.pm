package Mock::Tests::Binary;
use t::Utils;
use base 'Test::Class';
use Mock::Tests;
use Test::More;

my @list = qw( 10 2 43 0 9 84 45 255 );
sub t_01_set : Tests(1024) {
    for my $i (0..255) {
        local $list[3] = $i;
        my $bin = pack 'C*', @list; 
       my $set = mock->set( model => $i+1 => { data => $bin } );
        isa_ok $set, mock_class."::model";
        is $set->id, $i+1, 'id';
        is $set->data, $bin, 'binary data';

        use bytes;
        is bytes::length($set->data), 8, 'length';
    }
}

sub t_02_get : Tests(1024) {
    for my $i (0..255) {
        local $list[3] = $i;
        my $bin = pack 'C*', @list;
        my($get) = mock->get( model => $i+1 );
        isa_ok $get, mock_class."::model";
        is $get->id, $i+1, 'id';
        is $get->data, $bin, 'binary data';

        use bytes;
        is bytes::length($get->data), 8, 'length';
    }
}

1;

