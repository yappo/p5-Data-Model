package Mock::Tests::OnDuplicateKeyUpdate;
use t::Utils;
use base 'Test::Class';
use Mock::Tests;
use Test::More;


sub t_01_errors : Tests {

    do {
        local $@;
        eval { mock->set(
            not_has_key => { k1 => 1, k2 => 2, v => 3 },
            on_duplicate_key_update => {
                v => \'v + 1',
            },
        ) };
        like $@, qr/on_duplicate_key_update support: not_has_key not has key or unique index/, $@;
    };

    do {
        local $@;
        eval { mock->set(
            multi_unique_key => { k1 => 1, k2 => 2, v => 3 },
            on_duplicate_key_update => {
                v => \'v + 1',
            },
        ) };
        like $@, qr/on_duplicate_key_update support: multi_unique_key has multi unique key/, $@;
    };

    do {
        local $@;
        eval { mock->set(
            key_with_unique_key => { k1 => 1, k2 => 2, v => 3 },
            on_duplicate_key_update => {
                v => \'v + 1',
            },
        ) };
        like $@, qr/on_duplicate_key_update support: key_with_unique_key has multi unique key/, $@;
    };


    do {
        local $@;
        eval { mock->set(
            simple => { v => 3 },
            on_duplicate_key_update => {
                v => \'v + 1',
            },
        ) };
        like $@, qr/n_duplicate_key_update support: simple is insufficient keys/, $@;
    };

    do {
        local $@;
        eval { mock->set(
            simple_unique => '2' => { v => 3 },
            on_duplicate_key_update => {
                v => \'v + 1',
            },
        ) };
        like $@, qr/n_duplicate_key_update support: simple_unique is insufficient keys/, $@;
    };

    do {
        local $@;
        eval { mock->set(
            multi_key => '1' => { k2 => 2, v => 3 },
            on_duplicate_key_update => {
                v => \'v + 1',
            },
        ) };
        like $@, qr/n_duplicate_key_update support: multi_key is insufficient keys/, $@;
    };

    do {
        local $@;
        eval { mock->set(
            multi_unique => { k1 => 2, v => 3 },
            on_duplicate_key_update => {
                v => \'v + 1',
            },
        ) };
        like $@, qr/n_duplicate_key_update support: multi_unique is insufficient keys/, $@;
    };
}

sub _insert_single {
    my($table, $v, $get_v) = @_;

    for my $k (1..4) {
        mock->set(
            $table => { k => $k, v => $v },
            on_duplicate_key_update => {
                v => \'v + 1',
            },
        );

        my $g = mock->lookup( $table => $k );
        is($g->v, $get_v, "get: $table -> $k -> $get_v");

        my $table2 = "${table}2";
        mock->set(
            $table2 => { k => $k, v1 => $v, v2 => $get_v },
            on_duplicate_key_update => {
                v1 => \'v1 + 1',
                v2 => $get_v,
            },
        );

        my $g2 = mock->lookup( $table2 => $k );
        is($g2->v1, $get_v, "get v1: $table2 -> $k -> $get_v");
        is($g2->v2, $get_v, "get v2: $table2 -> $k -> $get_v");
    }
}

sub _insert_single_zero {
    my($table, $v) = @_;

    for my $k (1..4) {
        mock->set(
            $table => { k => $k, v => $v },
            on_duplicate_key_update => {
                v => 0,
            },
        );

        my $g = mock->lookup( $table => $k );
        is($g->v, 0, "get: $table -> $k -> 0");
    }
}

sub t_02_insert_single : Tests {
    for my $i (0..10) {
        _insert_single 'simple', 10, 10+$i;
        _insert_single 'simple_unique', 8282, 8282+$i;
    }

    _insert_single_zero 'simple', 1234;
    _insert_single_zero 'simple_unique', 5678;
}


sub _insert_multi {
    my($table, $v, $get_v) = @_;

    for my $k1 (1..4) {
        for my $k2 (1..4) {
            mock->set(
                $table => { k1 => $k1, k2 => $k2, v => $v },
                on_duplicate_key_update => {
                    v => \'v + 1',
                },
            );

            my $g = mock->lookup( $table => [$k1, $k2] );
            is($g->v, $get_v, "get: $table -> $k1, $k2 -> $get_v");
        }
    }
}

sub _insert_multi_zero {
    my($table, $v) = @_;

    for my $k1 (1..4) {
        for my $k2 (1..4) {
            mock->set(
                $table => { k1 => $k1, k2 => $k2, v => $v },
                on_duplicate_key_update => {
                    v => 0,
                },
            );

            my $g = mock->lookup( $table => [$k1, $k2] );
            is($g->v, 0, "get: $table -> $k1, $k2 -> 0");
        }
    }
}

sub t_03_insert_multi : Tests {
    for my $i (0..10) {
        _insert_multi 'multi_key', 32, 32+$i;
        _insert_multi 'multi_unique', 282, 282+$i;
    }

    _insert_multi_zero 'multi_key', 12345;
    _insert_multi_zero 'multi_unique', 67890;
}


sub t_04_insert_key_column : Tests {

    my $table = 'simple';
    for my $k (0..10) {
        my $v = $k*$k;
        mock->set(
            $table => $k => { v => $v },
            on_duplicate_key_update => {
                v => $v,
            },
        );

        my $g = mock->lookup( $table => $k );
        is($g->v, $v, "get key_column : $table -> $k -> $v");
    }

    $table = 'multi_key';
    for my $k1 (0..10) {
        for my $k2 (0..10) {
            my $v = (($k1*$k1)+($k2*$k2));
            mock->set(
                $table => [ $k1, $k2 ] => { v => $v },
                on_duplicate_key_update => {
                    v => $v,
                },
            );

            my $g = mock->lookup( $table => [$k1, $k2] );
            is($g->v, $v, "get key_column : $table -> $k1, $k2 -> $v");
        }
    }
}

1;

