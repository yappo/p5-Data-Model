package Mock::Tests::Default;
use t::Utils;
use base 'Test::Class';
use Mock::Tests;
use Test::More;

sub t_01_not_set : Tests(10) {
    my $set = mock->set( 'tbl' );
    isa_ok $set, mock_class."::tbl";
    is $set->id, 1, 'id';
    is $set->c_int1, 10, 'int';
    is $set->c_char1, 'foo', 'char';
    is $set->code1, 'bar', 'code';

    my($get) = mock->get( 'tbl' => 1 );
    isa_ok $get, mock_class."::tbl";
    is $get->id, 1, 'id';
    is $get->c_int1, 10, 'int';
    is $get->c_char1, 'foo', 'char';
    is $get->code1, 'bar', 'code';
}

sub t_01_set_values : Tests(10) {
    my $set = mock->set( 'tbl' => {
        c_int1  => 99,
        c_char1 => 'kyuukyuu',
        code1 => 'code',
    });
    isa_ok $set, mock_class."::tbl";
    is $set->id, 2, 'id';
    is $set->c_int1, 99, 'int';
    is $set->c_char1, 'kyuukyuu', 'char';
    is $set->code1, 'code', 'code';

    my($get) = mock->get( 'tbl' => 2 );
    isa_ok $get, mock_class."::tbl";
    is $get->id, 2, 'id';
    is $get->c_int1, 99, 'int';
    is $get->c_char1, 'kyuukyuu', 'char';
    is $get->code1, 'code', 'code';
}

1;

