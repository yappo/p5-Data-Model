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

sub empty_hash { +{} }

sub t_03_get_undef : Tests(2) {
    my $all = mock->get('tbl');
    ok($all, 'get all');

    my $undef = mock->get( tbl => undef );
    ok(!$undef, 'get undef is empty');
}


sub t_04_get_undef_with_deflate : Tests(3) {
    mock->set( tbl8 => { u8 => 1 } );
    mock->set( tbl8 => { u8 => 2 } );
    mock->set( tbl8 => { u8 => 3 } );

    my $all = mock->get('tbl8');
    ok($all, 'get all');

    my $undef = mock->get( tbl8 => undef );
    ok(!$undef, 'get undef is empty');

    my $hash;
    my $exists = mock->get( tbl8 => empty_hash->{user_id} );
    ok(!$exists, 'get undef is empty');
}

1;

