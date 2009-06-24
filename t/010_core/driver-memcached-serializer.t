use strict;
use warnings;
use t::Utils;
use Test::More;

our $has_dmp = 0;
if (eval "use Data::MessagePack; 1;") {
    plan tests => 48;
    $has_dmp = 1;
} else {
    plan tests => 20;
    $has_dmp = 0;
}

use Data::Model::Driver::Memcached;

sub run_tests {
    my $in = shift;

    my $pack = Data::Model::Driver::Memcached::Serializer::Default->serialize(
        undef, $in,
    );
    my $ret = Data::Model::Driver::Memcached::Serializer::Default->deserialize(
        undef, $pack,
    );

    is_deeply($ret, $in);

    if ($has_dmp) {
        $pack =~ s/^.//;
        my $pack2 = Data::MessagePack->pack($in);
        is($pack, $pack2, 'pack');
        my $ret2  = Data::MessagePack->unpack($pack);
        is_deeply($ret, $ret2, 'unpack');
    }
}

run_tests +{
    k_1 => undef,
};

run_tests +{
    k_1 => 2,
};

run_tests +{
    k_1 => 'hooo',
};

run_tests +{
    'xxx' => undef,
};

run_tests +{
    'xxx' => 2,
};

run_tests +{
    'xxx' => 'hooo',
};

run_tests +{
    k_1       => undef,
    k_2       => 'b',
    k_3       => 'hooo',
    'xxx'   => undef,
    'yyy'   => '25c',
    'zzz'   => 'hooo',
};

run_tests +{
    k_1  => 'k',
    k_2  => 'k2',
    k_3  => 'k33',
    k_4  => 'k444',
    k_5  => 'k5555',
    k_6  => 'k66666',
    k_7  => 'k777777',
    k_8  => 'k8888888',
    k_9  => 'k99999999',
    k_10 => 'k000000000',
    k_11 => 'k1111111111',
    k_12 => 'k22222222222',
    k_13 => 'k333333333333',
    k_14 => 'k4444444444444',
    k_15 => 'k55555555555555',
    k_16 => 'k666666666666666',
    k_17 => 'k7777777777777777',
    k_31 => ('a'x31),
    k_32 => ('b'x32),
    k_33 => ('c'x33),
    k_34 => ('f'x(256*256)),
    ('a'x31) => '3a',
    ('b'x32) => '3b',
    ('c'x33) => '3c',
    ('f'x(256*256)) => '3f',
};

run_tests +{
    k_1 => 2,
    k_3 => 4,
    k_5 => 6,
    k_7 => 8,
};

# Positive FixNum
run_tests +{
    'k_'.(0)    => 0,
    'k_'.(1)    => 1,
    'k_'.(0x7e) => 0x7e,
    'k_'.(0x7f) => 0x7f,
    'k_'.(0x80) => 0x80,
    'k_'.(0x81) => 0x81,
};

# uint 8
run_tests +{
    'k_'.(256-1) => (256-1),
    'k_'.(256)   => (256),
    'k_'.(256+1) => (256+1),
};

# uint 16
run_tests +{
    'k_'.(256*256-1) => (256*256-1),
    'k_'.(256*256)   => (256*256),
    'k_'.(256*256+1) => (256*256+1),
};

# uint 32
run_tests +{
    'k_'.(256*256*256-1) => (256*256*256-1),
    'k_'.(256*256*256)   => (256*256*256),
    'k_'.(256*256*256+1) => (256*256*256+1),
};

# uint 32
run_tests +{
    'k_'.(256*256*256*255+255) => (256*256*256*255+255),
};


do {
    local $has_dmp = 0;

    run_tests +{
        1 => 2,
        3 => 4,
        5 => 6,
        7 => 8,
    };

    # Positive FixNum
    run_tests +{
        (0)    => 0,
        (1)    => 1,
        (0x7e) => 0x7e,
        (0x7f) => 0x7f,
        (0x80) => 0x80,
        (0x81) => 0x81,
    };

    # uint 8
    run_tests +{
        (256-1) => (256-1),
        (256)   => (256),
        (256+1) => (256+1),
    };

    # uint 16
    run_tests +{
        (256*256-1) => (256*256-1),
        (256*256)   => (256*256),
        (256*256+1) => (256*256+1),
    };

    # uint 32
    run_tests +{
        (256*256*256-1) => (256*256*256-1),
        (256*256*256)   => (256*256*256),
        (256*256*256+1) => (256*256*256+1),
    };

    # uint 32
    run_tests +{
        (256*256*256*255+255) => (256*256*256*255+255),
    };
};
