package Mock::Tests::Index;
use t::Utils;
use base 'Test::Class';
use Mock::Tests;
use Test::More;


sub _08_key_get_1 {
    my($row, $key1, $key2, $key3) = @_;
    is $row->key1, $key1;
    is $row->key2, $key2;
    is $row->key3, $key3;
}
sub t_08_multi_column_primary_key : Tests {
    my $set1 = mock->set( multi_keys => [qw/ a001 b001 c001 /] );
    my $set2 = mock->set( multi_keys => [qw/ a001 b001 c002 /] );
    my $set3 = mock->set( multi_keys => [qw/ a001 b002 c001 /] );
    my $set4 = mock->set( multi_keys => [qw/ a001 b002 c002 /] );
    my $set5 = mock->set( multi_keys => [qw/ a002 b001 c001 /] );
    my $set6 = mock->set( multi_keys => [qw/ a002 b001 c002 /] );
    my $set7 = mock->set( multi_keys => [qw/ a002 b002 c001 /] );
    my $set8 = mock->set( multi_keys => [qw/ a002 b002 c002 /] );

    my $it1 = mock->get( multi_keys => 'a001', {
        order => [
            { key2 => 'ASC', },
            { key3 => 'DESC' },
        ],
    });
    _08_key_get_1($it1->next, 'a001', 'b001', 'c002');
    _08_key_get_1($it1->next, 'a001', 'b001', 'c001');
    _08_key_get_1($it1->next, 'a001', 'b002', 'c002');
    _08_key_get_1($it1->next, 'a001', 'b002', 'c001');
    ok !$it1->next, 'end of it1';

    my $it2 = mock->get( multi_keys => 'a002', {
        order => [
            { key2 => 'DESC', },
            { key3 => 'ASC' },
        ],
    });
    _08_key_get_1($it2->next, 'a002', 'b002', 'c001');
    _08_key_get_1($it2->next, 'a002', 'b002', 'c002');
    _08_key_get_1($it2->next, 'a002', 'b001', 'c001');
    _08_key_get_1($it2->next, 'a002', 'b001', 'c002');
    ok !$it2->next, 'end of it2';

    my $it3 = mock->get( multi_keys => [qw/ a001 b001 /], {
        order => [
            { key3 => 'ASC' },
        ],
    });
    _08_key_get_1($it3->next, 'a001', 'b001', 'c001');
    _08_key_get_1($it3->next, 'a001', 'b001', 'c002');
    ok !$it3->next, 'end of it3';

    my $it4 = mock->get( multi_keys => [qw/ a002 b002 /], {
        order => [
            { key3 => 'ASC' },
        ],
    });
    _08_key_get_1($it4->next, 'a002', 'b002', 'c001');
    _08_key_get_1($it4->next, 'a002', 'b002', 'c002');
    ok !$it4->next, 'end of it4';

    my $it5 = mock->get( multi_keys => [qw/ a001 b002 c001 /]);
    _08_key_get_1($it5->next, 'a001', 'b002', 'c001');
    ok !$it5->next, 'end of it5';

}

sub _08_unique_get_1 {
    my($row, $key, $unq1, $unq2, $unq3) = @_;
    is $row->key,  $key;
    is $row->unq1, $unq1;
    is $row->unq2, $unq2;
    is $row->unq3, $unq3;
}
sub t_08_multi_column_unique : Tests {
    my $set1 = mock->set( multi_unique => { unq1 => 'a001', unq2 => 'b001', unq3 => 'c001' } );
    my $set2 = mock->set( multi_unique => { unq1 => 'a001', unq2 => 'b001', unq3 => 'c002' } );
    my $set3 = mock->set( multi_unique => { unq1 => 'a001', unq2 => 'b002', unq3 => 'c001' } );
    my $set4 = mock->set( multi_unique => { unq1 => 'a001', unq2 => 'b002', unq3 => 'c002' } );
    my $set5 = mock->set( multi_unique => { unq1 => 'a002', unq2 => 'b001', unq3 => 'c001' } );
    my $set6 = mock->set( multi_unique => { unq1 => 'a002', unq2 => 'b001', unq3 => 'c002' } );
    my $set7 = mock->set( multi_unique => { unq1 => 'a002', unq2 => 'b002', unq3 => 'c001' } );
    my $set8 = mock->set( multi_unique => { unq1 => 'a002', unq2 => 'b002', unq3 => 'c002' } );

    my $it1 = mock->get( multi_unique => {
        index => { unq => 'a001' },
        order => [
            { unq2 => 'ASC', },
            { unq3 => 'DESC' },
        ],
    });
    _08_unique_get_1($it1->next, 2, 'a001', 'b001', 'c002');
    _08_unique_get_1($it1->next, 1, 'a001', 'b001', 'c001');
    _08_unique_get_1($it1->next, 4, 'a001', 'b002', 'c002');
    _08_unique_get_1($it1->next, 3, 'a001', 'b002', 'c001');
    ok !$it1->next, 'end of it1';

    my $it2 = mock->get( multi_unique => {
        index => { unq => 'a002' },
        order => [
            { unq2 => 'DESC', },
            { unq3 => 'ASC' },
        ],
    });
    _08_unique_get_1($it2->next, 7, 'a002', 'b002', 'c001');
    _08_unique_get_1($it2->next, 8, 'a002', 'b002', 'c002');
    _08_unique_get_1($it2->next, 5, 'a002', 'b001', 'c001');
    _08_unique_get_1($it2->next, 6, 'a002', 'b001', 'c002');
    ok !$it2->next, 'end of it2';

    my $it3 = mock->get( multi_unique => {
        index => { unq => [qw/ a001 b001 /] },
        order => [
            { unq3 => 'ASC' },
        ],
    });
    _08_unique_get_1($it3->next, 1, 'a001', 'b001', 'c001');
    _08_unique_get_1($it3->next, 2, 'a001', 'b001', 'c002');
    ok !$it3->next, 'end of it3';

    my $it4 = mock->get( multi_unique => {
        index => { unq => [qw/ a002 b002 /] },
        order => [
            { unq3 => 'ASC' },
        ],
    });
    _08_unique_get_1($it4->next, 7, 'a002', 'b002', 'c001');
    _08_unique_get_1($it4->next, 8, 'a002', 'b002', 'c002');
    ok !$it4->next, 'end of it4';

    my $it5 = mock->get( multi_unique => { index => { unq => [qw/ a001 b002 c001 /] } });
    _08_unique_get_1($it5->next, 3, 'a001', 'b002', 'c001');
    ok !$it5->next, 'end of it5';
}

sub _08_index_get_1 {
    my($row, $key, $idx1, $idx2, $idx3) = @_;
    is $row->key,  $key;
    is $row->idx1, $idx1;
    is $row->idx2, $idx2;
    is $row->idx3, $idx3;
}
sub t_08_multi_column_index : Tests {
    my $set1 = mock->set( multi_index => { idx1 => 'a001', idx2 => 'b001', idx3 => 'c001' } );
    my $set2 = mock->set( multi_index => { idx1 => 'a001', idx2 => 'b001', idx3 => 'c002' } );
    my $set3 = mock->set( multi_index => { idx1 => 'a001', idx2 => 'b002', idx3 => 'c001' } );
    my $set4 = mock->set( multi_index => { idx1 => 'a001', idx2 => 'b002', idx3 => 'c002' } );
    my $set5 = mock->set( multi_index => { idx1 => 'a002', idx2 => 'b001', idx3 => 'c001' } );
    my $set6 = mock->set( multi_index => { idx1 => 'a002', idx2 => 'b001', idx3 => 'c002' } );
    my $set7 = mock->set( multi_index => { idx1 => 'a002', idx2 => 'b002', idx3 => 'c001' } );
    my $set8 = mock->set( multi_index => { idx1 => 'a002', idx2 => 'b002', idx3 => 'c002' } );

    my $it1 = mock->get( multi_index => {
        index => { idx => 'a001' },
        order => [
            { idx2 => 'ASC', },
            { idx3 => 'DESC' },
        ],
    });
    _08_index_get_1($it1->next, 2, 'a001', 'b001', 'c002');
    _08_index_get_1($it1->next, 1, 'a001', 'b001', 'c001');
    _08_index_get_1($it1->next, 4, 'a001', 'b002', 'c002');
    _08_index_get_1($it1->next, 3, 'a001', 'b002', 'c001');
    ok !$it1->next, 'end of it1';

    my $it2 = mock->get( multi_index => {
        index => { idx => 'a002' },
        order => [
            { idx2 => 'DESC', },
            { idx3 => 'ASC' },
        ],
    });
    _08_index_get_1($it2->next, 7, 'a002', 'b002', 'c001');
    _08_index_get_1($it2->next, 8, 'a002', 'b002', 'c002');
    _08_index_get_1($it2->next, 5, 'a002', 'b001', 'c001');
    _08_index_get_1($it2->next, 6, 'a002', 'b001', 'c002');
    ok !$it2->next, 'end of it2';

    my $it3 = mock->get( multi_index => {
        index => { idx => [qw/ a001 b001 /] },
        order => [
            { idx3 => 'ASC' },
        ],
    });
    _08_index_get_1($it3->next, 1, 'a001', 'b001', 'c001');
    _08_index_get_1($it3->next, 2, 'a001', 'b001', 'c002');
    ok !$it3->next, 'end of it3';

    my $it4 = mock->get( multi_index => {
        index => { idx => [qw/ a002 b002 /] },
        order => [
            { idx3 => 'ASC' },
        ],
    });
    _08_index_get_1($it4->next, 7, 'a002', 'b002', 'c001');
    _08_index_get_1($it4->next, 8, 'a002', 'b002', 'c002');
    ok !$it4->next, 'end of it4';

    my $it5 = mock->get( multi_index => { index => { idx => [qw/ a001 b002 c001 /] } });
    _08_index_get_1($it5->next, 3, 'a001', 'b002', 'c001');
    ok !$it5->next, 'end of it5';
}

sub t_09_duped_primary_key : Tests {
    eval { mock->set( multi_keys => [qw/ a001 b001 c001 /] ) };
    ok $@;
}

sub t_09_duped_unique : Tests {
    eval { mock->set( multi_unique => { unq1 => 'a001', unq2 => 'b001', unq3 => 'c001' } ) };
    ok $@;
}

1;
