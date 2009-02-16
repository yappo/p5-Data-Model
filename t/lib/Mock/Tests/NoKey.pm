package Mock::Tests::NoKey;
use t::Utils;
use base 'Test::Class';
use Mock::Tests;
use Test::More;

sub _check_iterator {
    my($it, @checks) = @_;
    while (my $row = $it->next) {
        my $data = shift @checks;
        ok $data;
        is $row->c_int1, $data->{c_int1};
        is $row->c_int2, $data->{c_int2};
        is $row->c_char1, $data->{c_char1};
    }
}

sub t_01_set : Tests {
    my $ret1 = mock->set( not_key => { c_int1 => 1, c_int2 => 100, c_char1 => 'char' } );
    isa_ok $ret1, mock_class."::not_key";
    is $ret1->c_int1, 1;
    is $ret1->c_int2, 100;
    is $ret1->c_char1, 'char';

    my $ret2 = mock->set( not_key => { c_int1 => 1, c_int2 => 100, c_char1 => 'char' } );
    isa_ok $ret2, mock_class."::not_key";
    is $ret2->c_int1, 1;
    is $ret2->c_int2, 100;
    is $ret2->c_char1, 'char';

    my $ret3 = mock->set( not_key => { c_int1 => 2, c_int2 => 200, c_char1 => 'char' } );
    isa_ok $ret3, mock_class."::not_key";
    is $ret3->c_int1, 2;
    is $ret3->c_int2, 200;
    is $ret3->c_char1, 'char';

    my $ret4 = mock->set( not_key => { c_int1 => 3, c_int2 => 200, c_char1 => 'lock' } );
    isa_ok $ret4, mock_class."::not_key";
    is $ret4->c_int1, 3;
    is $ret4->c_int2, 200;
    is $ret4->c_char1, 'lock';

    my $ret5 = mock->set( not_key => { c_int1 => 1, c_int2 => 101, c_char1 => 'check' } );
    isa_ok $ret5, mock_class."::not_key";
    is $ret5->c_int1, 1;
    is $ret5->c_int2, 101;
    is $ret5->c_char1, 'check';
}

sub t_02_c_int1 : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                c_int1 => 1,
            ],
            order => [ { c_int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ c_int1 => 1, c_int2 => 100, c_char1 => 'char' },
        +{ c_int1 => 1, c_int2 => 100, c_char1 => 'char' },
        +{ c_int1 => 1, c_int2 => 101, c_char1 => 'check' },
    );
}

sub t_03_c_int2 : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                c_int2 => 200,
            ],
            order => [ { c_int1 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ c_int1 => 2, c_int2 => 200, c_char1 => 'char' },
        +{ c_int1 => 3, c_int2 => 200, c_char1 => 'lock' },
    );
}

sub t_04_c_char1 : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                c_char1 => 'char',
            ],
            order => [ { c_int1 => 'ASC' }, { c_int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ c_int1 => 1, c_int2 => 100, c_char1 => 'char' },
        +{ c_int1 => 1, c_int2 => 100, c_char1 => 'char' },
        +{ c_int1 => 2, c_int2 => 200, c_char1 => 'char' },
    );
}

sub t_05_c_char1_prefix : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                c_char1 => { LIKE => 'ch%' },
            ],
            order => [ { c_int1 => 'ASC' }, { c_int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ c_int1 => 1, c_int2 => 100, c_char1 => 'char' },
        +{ c_int1 => 1, c_int2 => 100, c_char1 => 'char' },
        +{ c_int1 => 1, c_int2 => 101, c_char1 => 'check' },
        +{ c_int1 => 2, c_int2 => 200, c_char1 => 'char' },
    );
}

sub t_06_c_char1_suffix : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                c_char1 => { LIKE => '%ck' },
            ],
            order => [ { c_int1 => 'ASC' }, { c_int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ c_int1 => 1, c_int2 => 101, c_char1 => 'check' },
        +{ c_int1 => 3, c_int2 => 200, c_char1 => 'lock' },
    );
}

sub t_07_c_char1_grep_1 : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                c_char1 => { LIKE => '%c%' },
            ],
            order => [ { c_int1 => 'ASC' }, { c_int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ c_int1 => 1, c_int2 => 100, c_char1 => 'char' },
        +{ c_int1 => 1, c_int2 => 100, c_char1 => 'char' },
        +{ c_int1 => 1, c_int2 => 101, c_char1 => 'check' },
        +{ c_int1 => 2, c_int2 => 200, c_char1 => 'char' },
        +{ c_int1 => 3, c_int2 => 200, c_char1 => 'lock' },
    );
}

sub t_07_c_char1_grep_2 : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                c_char1 => { LIKE => '%h%' },
            ],
            order => [ { c_int1 => 'ASC' }, { c_int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ c_int1 => 1, c_int2 => 100, c_char1 => 'char' },
        +{ c_int1 => 1, c_int2 => 100, c_char1 => 'char' },
        +{ c_int1 => 1, c_int2 => 101, c_char1 => 'check' },
        +{ c_int1 => 2, c_int2 => 200, c_char1 => 'char' },
    );
}

sub t_07_c_char1_grep_3 : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                c_char1 => { LIKE => '%h_r%' },
            ],
            order => [ { c_int1 => 'ASC' }, { c_int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ c_int1 => 1, c_int2 => 100, c_char1 => 'char' },
        +{ c_int1 => 1, c_int2 => 100, c_char1 => 'char' },
        +{ c_int1 => 2, c_int2 => 200, c_char1 => 'char' },
    );
}

sub t_07_c_char1_grep_4 : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                c_char1 => { LIKE => '%h.r%' },
            ],
            order => [ { c_int1 => 'ASC' }, { c_int2 => 'ASC' } ],
        }
    );
    ok !$it;
}

sub t_07_c_char1_grep_5 : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                c_char1 => { LIKE => '.+' },
            ],
            order => [ { c_int1 => 'ASC' }, { c_int2 => 'ASC' } ],
        }
    );
    ok !$it;
}

sub t_08_op_1 : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                c_int1 => { 'NOT IN' => [ 1, 2 ] },
            ],
            order => [ { c_int1 => 'ASC' }, { c_int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ c_int1 => 3, c_int2 => 200, c_char1 => 'lock' },
    );
}

sub t_08_op_2 : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                c_int1 => { '!=' => 1 },
            ],
            order => [ { c_int1 => 'ASC' }, { c_int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ c_int1 => 2, c_int2 => 200, c_char1 => 'char' },
        +{ c_int1 => 3, c_int2 => 200, c_char1 => 'lock' },
    );
}

sub t_08_op_3 : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                c_int1 => { '>' => 1 },
            ],
            order => [ { c_int1 => 'ASC' }, { c_int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ c_int1 => 2, c_int2 => 200, c_char1 => 'char' },
        +{ c_int1 => 3, c_int2 => 200, c_char1 => 'lock' },
    );
}

sub t_08_op_4 : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                c_int2 => { '>' => 100 },
                c_int2 => { '<' => 200 },
            ],
            order => [ { c_int1 => 'ASC' }, { c_int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ c_int1 => 1, c_int2 => 101, c_char1 => 'check' },
    );
}

sub t_08_op_5 : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                -or => [
                    c_int1 => { '>' => 2 },
                    c_int2 => { '<' => 200 },
                ],
            ],
            order => [ { c_int1 => 'ASC' }, { c_int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ c_int1 => 1, c_int2 => 100, c_char1 => 'char' },
        +{ c_int1 => 1, c_int2 => 100, c_char1 => 'char' },
        +{ c_int1 => 1, c_int2 => 101, c_char1 => 'check' },
        +{ c_int1 => 3, c_int2 => 200, c_char1 => 'lock' },
    );
}

sub t_09_in : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                -or => [
                    c_int2 => { IN => [ 101, 200 ] },
                ],
            ],
            order => [ { c_int1 => 'ASC' }, { c_int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ c_int1 => 1, c_int2 => 101, c_char1 => 'check' },
        +{ c_int1 => 2, c_int2 => 200, c_char1 => 'char' },
        +{ c_int1 => 3, c_int2 => 200, c_char1 => 'lock' },
    );
}

sub t_10_get_all : Tests {
    my $it = mock->get(
        'not_key',
        +{
            where => [ c_int1 => +{ '!=' => 100 } ],
            order => [ { c_int1 => 'ASC' }, { c_int2 => 'ASC' } ],
        }
    );
    ok $it, 'get';
    _check_iterator($it,
        +{ c_int1 => 1, c_int2 => 100, c_char1 => 'char' },
        +{ c_int1 => 1, c_int2 => 100, c_char1 => 'char' },
        +{ c_int1 => 1, c_int2 => 101, c_char1 => 'check' },
        +{ c_int1 => 2, c_int2 => 200, c_char1 => 'char' },
        +{ c_int1 => 3, c_int2 => 200, c_char1 => 'lock' },
    );
}

sub t_50_and : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                c_int1 => 1,
                c_int2 => 100,
            ],
            order => [ { c_int1 => 'ASC' }, { c_int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ c_int1 => 1, c_int2 => 100, c_char1 => 'char' },
        +{ c_int1 => 1, c_int2 => 100, c_char1 => 'char' },
    );
}

sub t_50_or : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                -or => [
                    c_int1 => 1,
                    c_int2 => 100,
                ],
            ],
            order => [ { c_int1 => 'ASC' }, { c_int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ c_int1 => 1, c_int2 => 100, c_char1 => 'char' },
        +{ c_int1 => 1, c_int2 => 100, c_char1 => 'char' },
        +{ c_int1 => 1, c_int2 => 101, c_char1 => 'check' },
    );
}

sub t_51_and_or : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                -and => [
                    c_char1 => 'char',
                    -or   => [
                        c_int2 => 100,
                        c_int2 => 200,
                    ],
                ]
            ],
            order => [ { c_int1 => 'ASC' }, { c_int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ c_int1 => 1, c_int2 => 100, c_char1 => 'char' },
        +{ c_int1 => 1, c_int2 => 100, c_char1 => 'char' },
        +{ c_int1 => 2, c_int2 => 200, c_char1 => 'char' },
    );
}

sub t_61_update : Tests {
    my($get) = mock->get(
        not_key => +{ 
            where => [
                c_int1 => 1,
            ],
        }
    );
    isa_ok $get, mock_class."::not_key";
    $get->c_char1('update');
    my $set = $get->update;
    ok !$set;
}

sub t_62_delete : Tests {
    my($get) = mock->get(
        not_key => +{ 
            where => [
                c_int1 => 1,
            ],
        }
    );
    isa_ok $get, mock_class."::not_key";
    ok(!$get->delete);
    ($get) = mock->get(
        not_key => +{ 
            where => [
                c_int1 => 1,
            ],
        }
    );
    isa_ok $get, mock_class."::not_key";
}

sub t_71_direct_update : Tests {

    my $set1 = mock->set( not_key => { c_int1 => 99, c_int2 => 999, c_char1 => 'kyu' } );
    isa_ok $set1, mock_class."::not_key";
    is $set1->c_int1, 99;
    is $set1->c_int2, 999;
    is $set1->c_char1, 'kyu';

    ok mock->update_direct(
        not_key => +{
            where => [
                c_char1 => 'kyu',
            ],
        },
        +{
            c_int1  => 100,
            c_int2  => 1000,
            c_char1 => 'sen',
        },
    );

    my $it = mock->get(
        'not_key',
        +{
            where => [ c_int1 => +{ '!=' => 100 } ],
            order => [ { c_int1 => 'ASC' }, { c_int2 => 'ASC' } ],
        }
    );
    ok $it, 'get';
    _check_iterator($it,
        +{ c_int1 => 1, c_int2 => 100, c_char1 => 'char' },
        +{ c_int1 => 1, c_int2 => 100, c_char1 => 'char' },
        +{ c_int1 => 1, c_int2 => 101, c_char1 => 'check' },
        +{ c_int1 => 2, c_int2 => 200, c_char1 => 'char' },
        +{ c_int1 => 3, c_int2 => 200, c_char1 => 'lock' },
    );

    my($get1) = mock->get( not_key => { where => [ c_int1 => 100 ] } );
    isa_ok $get1, mock_class."::not_key";
    is $get1->c_int1, 100;
    is $get1->c_int2, 1000;
    is $get1->c_char1, 'sen';
}

1;
