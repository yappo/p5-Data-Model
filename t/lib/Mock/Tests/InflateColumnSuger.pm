package Mock::Tests::InflateColumnSuger;
use t::Utils;
use base 'Test::Class';
use Mock::Tests;
use Test::More;

sub t_01_set_tbl : Tests(2) {
    use utf8;
    ok(mock->set( tbl => { name => 'おおさわ', data => TestDat->new( data => 'data' ) } ));
    ok(mock->set( tbl => { name => 'かずひろ', data => TestDat->new( data => 'value' ) } ));
}

sub t_02_set_tbl2 : Tests(2) {
    use utf8;
    ok(mock->set( tbl2 => { name2 => 'おおさわ', data2 => TestDat->new( data => 'data' ) } ));
    ok(mock->set( tbl2 => { name2 => 'かずひろ', data2 => TestDat->new( data => 'value' ) } ));
}

sub t_11_get_tbl : Tests(6) {
    my @rows = mock->lookup_multi( tbl => [qw/ 1 2 /] );
    {
        use utf8;
        is $rows[0]->name, 'おおさわ', 'name utf8';
    }
    is ref($rows[0]->data), 'TestDat', 'TestDat class';
    is $rows[0]->data->data, 'data', 'TestDat->data';

    {
        use utf8;
        is $rows[1]->name, 'かずひろ', 'name utf8';
    }
    is ref($rows[1]->data), 'TestDat', 'TestDat class';
    is $rows[1]->data->data, 'value', 'TestDat->data';
}

sub t_12_get_tbl : Tests(6) {
    my @rows = mock->lookup_multi( tbl2 => [qw/ 1 2 /] );
    {
        use utf8;
        is $rows[0]->name2, 'おおさわ', 'name utf8';
    }
    is ref($rows[0]->data2), 'TestDat', 'TestDat class';
    is $rows[0]->data2->data, 'data', 'TestDat->data';

    {
        use utf8;
        is $rows[1]->name2, 'かずひろ', 'name utf8';
    }
    is ref($rows[1]->data2), 'TestDat', 'TestDat class';
    is $rows[1]->data2->data, 'value', 'TestDat->data';
}

1;

