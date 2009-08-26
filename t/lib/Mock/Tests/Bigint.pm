package Mock::Tests::Bigint;
use t::Utils;
use base 'Test::Class';
use Mock::Tests;
use Test::More;

sub _run_tests {
    my($key, $value) = @_;

    mock->set( simple => { k => $key, i => $value } );
    my $row = mock->lookup( simple => $key );
    is($row->i, $value, "test $value");
}

sub t_01_test : Tests {

    my $key = 1;
    for my $value ((
        2147483648,
        2147483648-1,
        2147483648+1,
        4294967296,
        4294967296-1,
        4294967296+1,
        1,
        0,
    )) {
        _run_tests $key++ => $value;
        _run_tests $key++ => ($value*-1);
    }

    # 10G 100G 1T 10T 100T
    my $size = 1024*1024*1024;

    _run_tests $key++ => $size*10;
    _run_tests $key++ => ($size*10*-1);

    _run_tests $key++ => $size*100;
    _run_tests $key++ => ($size*100*-1);

    _run_tests $key++ => $size*1024;
    _run_tests $key++ => ($size*1024*-1);

    _run_tests $key++ => $size*1024*10;
    _run_tests $key++ => ($size*1024*10*-1);

    _run_tests $key++ => $size*1024*100;
    _run_tests $key++ => ($size*1024*100*-1);

}

1;

