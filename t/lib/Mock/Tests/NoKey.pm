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
        is $row->int1, $data->{int1};
        is $row->int2, $data->{int2};
        is $row->char1, $data->{char1};
    }
}

sub t_01_set : Tests {
    my $ret1 = mock->set( not_key => { int1 => 1, int2 => 100, char1 => 'char' } );
    isa_ok $ret1, mock_class."::not_key";
    is $ret1->int1, 1;
    is $ret1->int2, 100;
    is $ret1->char1, 'char';

    my $ret2 = mock->set( not_key => { int1 => 1, int2 => 100, char1 => 'char' } );
    isa_ok $ret2, mock_class."::not_key";
    is $ret2->int1, 1;
    is $ret2->int2, 100;
    is $ret2->char1, 'char';

    my $ret3 = mock->set( not_key => { int1 => 2, int2 => 200, char1 => 'char' } );
    isa_ok $ret3, mock_class."::not_key";
    is $ret3->int1, 2;
    is $ret3->int2, 200;
    is $ret3->char1, 'char';

    my $ret4 = mock->set( not_key => { int1 => 3, int2 => 200, char1 => 'lock' } );
    isa_ok $ret4, mock_class."::not_key";
    is $ret4->int1, 3;
    is $ret4->int2, 200;
    is $ret4->char1, 'lock';

    my $ret5 = mock->set( not_key => { int1 => 1, int2 => 101, char1 => 'check' } );
    isa_ok $ret5, mock_class."::not_key";
    is $ret5->int1, 1;
    is $ret5->int2, 101;
    is $ret5->char1, 'check';
}

sub t_02_int1 : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                int1 => 1,
            ],
            order => [ { int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ int1 => 1, int2 => 100, char1 => 'char' },
        +{ int1 => 1, int2 => 100, char1 => 'char' },
        +{ int1 => 1, int2 => 101, char1 => 'check' },
    );
}

sub t_03_int2 : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                int2 => 200,
            ],
            order => [ { int1 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ int1 => 2, int2 => 200, char1 => 'char' },
        +{ int1 => 3, int2 => 200, char1 => 'lock' },
    );
}

sub t_04_char1 : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                char1 => 'char',
            ],
            order => [ { int1 => 'ASC' }, { int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ int1 => 1, int2 => 100, char1 => 'char' },
        +{ int1 => 1, int2 => 100, char1 => 'char' },
        +{ int1 => 2, int2 => 200, char1 => 'char' },
    );
}

sub t_05_char1_prefix : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                char1 => { LIKE => 'ch%' },
            ],
            order => [ { int1 => 'ASC' }, { int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ int1 => 1, int2 => 100, char1 => 'char' },
        +{ int1 => 1, int2 => 100, char1 => 'char' },
        +{ int1 => 1, int2 => 101, char1 => 'check' },
        +{ int1 => 2, int2 => 200, char1 => 'char' },
    );
}

sub t_06_char1_suffix : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                char1 => { LIKE => '%ck' },
            ],
            order => [ { int1 => 'ASC' }, { int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ int1 => 1, int2 => 101, char1 => 'check' },
        +{ int1 => 3, int2 => 200, char1 => 'lock' },
    );
}

sub t_07_char1_grep_1 : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                char1 => { LIKE => '%c%' },
            ],
            order => [ { int1 => 'ASC' }, { int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ int1 => 1, int2 => 100, char1 => 'char' },
        +{ int1 => 1, int2 => 100, char1 => 'char' },
        +{ int1 => 1, int2 => 101, char1 => 'check' },
        +{ int1 => 2, int2 => 200, char1 => 'char' },
        +{ int1 => 3, int2 => 200, char1 => 'lock' },
    );
}

sub t_07_char1_grep_2 : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                char1 => { LIKE => '%h%' },
            ],
            order => [ { int1 => 'ASC' }, { int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ int1 => 1, int2 => 100, char1 => 'char' },
        +{ int1 => 1, int2 => 100, char1 => 'char' },
        +{ int1 => 1, int2 => 101, char1 => 'check' },
        +{ int1 => 2, int2 => 200, char1 => 'char' },
    );
}

sub t_07_char1_grep_3 : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                char1 => { LIKE => '%h_r%' },
            ],
            order => [ { int1 => 'ASC' }, { int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ int1 => 1, int2 => 100, char1 => 'char' },
        +{ int1 => 1, int2 => 100, char1 => 'char' },
        +{ int1 => 2, int2 => 200, char1 => 'char' },
    );
}

sub t_07_char1_grep_4 : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                char1 => { LIKE => '%h.r%' },
            ],
            order => [ { int1 => 'ASC' }, { int2 => 'ASC' } ],
        }
    );
    ok !$it;
}

sub t_07_char1_grep_5 : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                char1 => { LIKE => '.+' },
            ],
            order => [ { int1 => 'ASC' }, { int2 => 'ASC' } ],
        }
    );
    ok !$it;
}

sub t_08_op_1 : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                int1 => { 'NOT IN' => [ 1, 2 ] },
            ],
            order => [ { int1 => 'ASC' }, { int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ int1 => 3, int2 => 200, char1 => 'lock' },
    );
}

sub t_08_op_2 : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                int1 => { '!=' => 1 },
            ],
            order => [ { int1 => 'ASC' }, { int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ int1 => 2, int2 => 200, char1 => 'char' },
        +{ int1 => 3, int2 => 200, char1 => 'lock' },
    );
}

sub t_08_op_3 : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                int1 => { '>' => 1 },
            ],
            order => [ { int1 => 'ASC' }, { int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ int1 => 2, int2 => 200, char1 => 'char' },
        +{ int1 => 3, int2 => 200, char1 => 'lock' },
    );
}

sub t_08_op_4 : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                int2 => { '>' => 100 },
                int2 => { '<' => 200 },
            ],
            order => [ { int1 => 'ASC' }, { int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ int1 => 1, int2 => 101, char1 => 'check' },
    );
}

sub t_08_op_5 : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                -or => [
                    int1 => { '>' => 2 },
                    int2 => { '<' => 200 },
                ],
            ],
            order => [ { int1 => 'ASC' }, { int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ int1 => 1, int2 => 100, char1 => 'char' },
        +{ int1 => 1, int2 => 100, char1 => 'char' },
        +{ int1 => 1, int2 => 101, char1 => 'check' },
        +{ int1 => 3, int2 => 200, char1 => 'lock' },
    );
}

sub t_09_in : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                -or => [
                    int2 => { IN => [ 101, 200 ] },
                ],
            ],
            order => [ { int1 => 'ASC' }, { int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ int1 => 1, int2 => 101, char1 => 'check' },
        +{ int1 => 2, int2 => 200, char1 => 'char' },
        +{ int1 => 3, int2 => 200, char1 => 'lock' },
    );
}

sub t_50_and : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                int1 => 1,
                int2 => 100,
            ],
            order => [ { int1 => 'ASC' }, { int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ int1 => 1, int2 => 100, char1 => 'char' },
        +{ int1 => 1, int2 => 100, char1 => 'char' },
    );
}

sub t_50_or : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                -or => [
                    int1 => 1,
                    int2 => 100,
                ],
            ],
            order => [ { int1 => 'ASC' }, { int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ int1 => 1, int2 => 100, char1 => 'char' },
        +{ int1 => 1, int2 => 100, char1 => 'char' },
        +{ int1 => 1, int2 => 101, char1 => 'check' },
    );
}

sub t_51_and_or : Tests {
    my $it = mock->get(
        not_key => +{ 
            where => [
                -and => [
                    char1 => 'char',
                    -or   => [
                        int2 => 100,
                        int2 => 200,
                    ],
                ]
            ],
            order => [ { int1 => 'ASC' }, { int2 => 'ASC' } ],
        }
    );
    ok $it;
    _check_iterator($it,
        +{ int1 => 1, int2 => 100, char1 => 'char' },
        +{ int1 => 1, int2 => 100, char1 => 'char' },
        +{ int1 => 2, int2 => 200, char1 => 'char' },
    );
}

sub t_61_update : Tests {
    my($get) = mock->get(
        not_key => +{ 
            where => [
                int1 => 1,
            ],
        }
    );
    isa_ok $get, mock_class."::not_key";
    $get->char1('update');
    my $set = $get->update;
    ok !$set;
}

sub t_62_delete : Tests {
    my($get) = mock->get(
        not_key => +{ 
            where => [
                int1 => 1,
            ],
        }
    );
    isa_ok $get, mock_class."::not_key";
    ok(!$get->delete);
    ($get) = mock->get(
        not_key => +{ 
            where => [
                int1 => 1,
            ],
        }
    );
    isa_ok $get, mock_class."::not_key";
}

sub t_71_direct_update : Tests {

    my $set1 = mock->set( not_key => { int1 => 99, int2 => 999, char1 => 'kyu' } );
    isa_ok $set1, mock_class."::not_key";
    is $set1->int1, 99;
    is $set1->int2, 999;
    is $set1->char1, 'kyu';

    ok mock->update_direct(
        not_key => +{
            where => [
                char1 => 'kyu',
            ],
        },
        +{
            int1  => 100,
            int2  => 1000,
            char1 => 'sen',
        },
    );

    my $it = mock->get(
        'not_key',
        +{
            where => [ int1 => +{ '!=' => 100 } ],
            order => [ { int1 => 'ASC' }, { int2 => 'ASC' } ],
        }
    );
    ok $it, 'get';
    _check_iterator($it,
        +{ int1 => 1, int2 => 100, char1 => 'char' },
        +{ int1 => 1, int2 => 100, char1 => 'char' },
        +{ int1 => 1, int2 => 101, char1 => 'check' },
        +{ int1 => 2, int2 => 200, char1 => 'char' },
        +{ int1 => 3, int2 => 200, char1 => 'lock' },
    );

    my($get1) = mock->get( not_key => { where => [ int1 => 100 ] } );
    isa_ok $get1, mock_class."::not_key";
    is $get1->int1, 100;
    is $get1->int2, 1000;
    is $get1->char1, 'sen';
}

1;
