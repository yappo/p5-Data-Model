use t::Utils;
use Test::More;

my $memcached_bin     = $ENV{TEST_MEMCACHED_BIN};
eval "use Cache::Memcached::Fast";
plan skip_all => "Cache::Memcached::Fast required for testing memcached driver" if $@;
eval "use Test::TCP";
plan skip_all => "Test::TCP required for testing memcached driver" if $@;
unless ($memcached_bin && -x $memcached_bin) {
    plan skip_all => "Set TEST_MEMCACHED_BIN environment variable to run this test";
}
plan tests => 133;

{
    package Schema;
    use base 'Data::Model';
    use Data::Model::Schema;
    use Data::Model::Driver::Memcached;

    install_model model1 => schema {
        key 'id';
        index 'name';
        columns qw/id name nickname/;
    };
    install_model model2 => schema {
        key 'id';
        index 'name';
        columns qw/id name nickname/;
        schema_options column_name_rename => {
            id       => 1,
            name     => 2,
            nickname => 3,
        };
    };
}
my $db = Schema->new;

my $port = empty_port();
my $memd = Cache::Memcached::Fast->new({ servers => [ { address => "localhost:$port" }, ], });
test_tcp(
    client => sub {
        main();
    },
    server => sub {
        exec $memcached_bin, '-p', $port;
    },
    port => $port,
);

sub run_tests {
    my $conf    = shift;
    my $model   = $conf->{model};
    my $key     = $conf->{key};
    my $columns = $conf->{set};
    my $from    = (caller(1))[3];
    $from       =~ s/.+:://;

    $db->set_driver( $model => $conf->{driver} );

    # set
    $db->set(
        $model => $key => $columns,
    );

    my $ret = $memd->get( "$model:$key" );
    is_deeply( $ret, $conf->{hash}->[0], "$from: memcached get" );

    # get
    my @lookup_multi = $db->lookup_multi( $model => [ $key ] );
    is($lookup_multi[0]->id,       $key,                 "$from: id");
    is($lookup_multi[0]->name,     $columns->{name},     "$from: name");
    is($lookup_multi[0]->nickname, $columns->{nickname}, "$from: nickname");

    my $lookup = $db->lookup( $model => $key );
    is($lookup->id,       $key,                 "$from: id");
    is($lookup->name,     $columns->{name},     "$from: name");
    is($lookup->nickname, $columns->{nickname}, "$from: nickname");

    ($lookup) = $db->get( $model => $key );
    is($lookup->id,       $key,                 "$from: id");
    is($lookup->name,     $columns->{name},     "$from: name");
    is($lookup->nickname, $columns->{nickname}, "$from: nickname");

    # update
    while (my($k, $v) = each %{ $conf->{update} }) {
        $lookup->$k($v);
    }
    $lookup->update;

    $ret = $memd->get( "$model:$key" );
    is_deeply( $ret, $conf->{hash}->[1], "$from: memcached get (update)" );

    $lookup = $db->lookup( $model => $key );
    is($lookup->id,       $key,                                                "$from: id");
    is($lookup->name,     ($conf->{update}{name}     || $columns->{name}),     "$from: name");
    is($lookup->nickname, ($conf->{update}{nickname} || $columns->{nickname}), "$from: nickname");

    # replace
    $db->replace(
        $model => $key => $columns,
    );

    $ret = $memd->get( "$model:$key" );
    is_deeply( $ret, $conf->{hash}->[0], "$from: memcached get (replace)" );

    $lookup = $db->lookup( $model => $key );
    is($lookup->id,       $key,                 "$from: id");
    is($lookup->name,     $columns->{name},     "$from: name");
    is($lookup->nickname, $columns->{nickname}, "$from: nickname");

    # delete
    ok($lookup->delete, "$from: deleted");
}


sub column_name_rename {
    run_tests +{
        driver => Data::Model::Driver::Memcached->new(
            memcached => $memd
        ),
        model  => 'model2',
        key    => 'kristate',
        set    => {
            name     => 'takashi',
            nickname => 'tashikani',
        },
        update => {
            name     => 'name',
            nickname => 'nickname',
        },
        hash   => [
            {
                1 => 'kristate',
                2 => 'takashi',
                3 => 'tashikani',
            },
            {
                1 => 'kristate',
                2 => 'name',
                3 => 'nickname',
            },
        ],
    };
}
sub ignore_undef_value {
    run_tests +{
        driver => Data::Model::Driver::Memcached->new(
            memcached => $memd,
            ignore_undef_value => 1,
        ),
        model  => 'model1',
        key    => 'kristate',
        set    => {
            name     => 'takashi',
            nickname => undef,
        },
        update => {
            name     => 'name',
        },
        hash   => [
            {
                id   => 'kristate',
                name => 'takashi',
            },
            {
                id   => 'kristate',
                name => 'name',
            },
        ],
    };
}
sub strip_keys {
    run_tests +{
        driver => Data::Model::Driver::Memcached->new(
            memcached => $memd,
            strip_keys => 1,
        ),
        model  => 'model1',
        key    => 'kristate',
        set    => {
            name     => 'takashi',
            nickname => 'tashikani',
        },
        update => {
            name     => 'name',
            nickname => 'nickname',
        },
        hash   => [
            {
                name     => 'takashi',
                nickname => 'tashikani',
            },
            {
                name     => 'name',
                nickname => 'nickname',
            },
        ],
    };
}

sub column_name_rename_ignore_undef_value {
    run_tests +{
        driver => Data::Model::Driver::Memcached->new(
            memcached => $memd,
            ignore_undef_value => 1,
        ),
        model  => 'model2',
        key    => 'kristate',
        set    => {
            name     => 'takashi',
        },
        update => {
            name     => 'name',
            nickname => 'nickname',
        },
        hash   => [
            {
                1 => 'kristate',
                2 => 'takashi',
            },
            {
                1 => 'kristate',
                2 => 'name',
                3 => 'nickname',
            },
        ],
    };
}
sub column_name_rename_strip_keys {
    run_tests +{
        driver => Data::Model::Driver::Memcached->new(
            memcached => $memd,
            strip_keys => 1,
        ),
        model  => 'model2',
        key    => 'kristate',
        set    => {
            name     => 'takashi',
            nickname => undef,
        },
        update => {
            name     => 'name',
            nickname => 'nickname',
        },
        hash   => [
            {
                2 => 'takashi',
                3 => undef,
            },
            {
                2 => 'name',
                3 => 'nickname',
            },
        ],
    };
}

sub ignore_undef_value_strip_keys {
    run_tests +{
        driver => Data::Model::Driver::Memcached->new(
            memcached => $memd,
            ignore_undef_value => 1,
            strip_keys => 1,
        ),
        model  => 'model1',
        key    => 'kristate',
        set    => {
            name     => 'takashi',
        },
        update => {
            name     => 'name',
        },
        hash   => [
            {
                name => 'takashi',
            },
            {
                name => 'name',
            },
        ],
    };
}

sub all {
    run_tests +{
        driver => Data::Model::Driver::Memcached->new(
            memcached => $memd,
            ignore_undef_value => 1,
            strip_keys => 1,
        ),
        model  => 'model2',
        key    => 'kristate',
        set    => {
            name     => 'takashi',
        },
        update => {
            name     => 'name',
            nickname => undef,
        },
        hash   => [
            {
                2 => 'takashi',
            },
            {
                2 => 'name',
            },
        ],
    };
}

sub main {
    column_name_rename;
    ignore_undef_value;
    strip_keys;

    column_name_rename_ignore_undef_value;
    column_name_rename_strip_keys;

    ignore_undef_value_strip_keys;
    all;
}
