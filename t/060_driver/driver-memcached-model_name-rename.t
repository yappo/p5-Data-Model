use t::Utils;
use Test::More tests => 11;

my $memcached_bin     = $ENV{TEST_MEMCACHED_BIN};
eval "use Cache::Memcached::Fast";
plan skip_all => "Cache::Memcached::Fast required for testing memcached driver" if $@;
eval "use Test::TCP";
plan skip_all => "Test::TCP required for testing memcached driver" if $@;
unless ($memcached_bin && -x $memcached_bin) {
    plan skip_all => "Set TEST_MEMCACHED_BIN environment variable to run this test";
}

my $port = empty_port();
my $memd = Cache::Memcached::Fast->new({ servers => [ { address => "localhost:$port" }, ], });
test_tcp(
    client => sub {
        run_tests();
    },
    server => sub {
        exec $memcached_bin, '-p', $port;
    },
    port => $port,
);


sub run_tests {
    {
        package Schema;
        use base 'Data::Model';
        use Data::Model::Schema;
        use Data::Model::Driver::Memcached;

        base_driver( Data::Model::Driver::Memcached->new(
            memcached => $memd,
        ) );
        install_model model => schema {
            key 'id';
            index 'name';
            columns qw/id name nickname/;
            schema_options model_name_realname => 'x';
        };
    }

    my $model = Schema->new;
    $model->set(
        model => 'kristate', {
            name     => 'takashi',
            nickname => 'tashikani',
        }
    );

    my $ret = $memd->get( 'x:kristate' );
    is_deeply( $ret, { id => 'kristate', name => 'takashi', nickname => 'tashikani' } );

    my @lookup_multi = $model->lookup_multi( model => 'kristate' );
    is($lookup_multi[0]->id, 'kristate', 'id');
    is($lookup_multi[0]->name, 'takashi', 'name');
    is($lookup_multi[0]->nickname, 'tashikani', 'nickname');

    my $lookup = $model->lookup( model => 'kristate' );
    is($lookup->id, 'kristate', 'id');
    is($lookup->name, 'takashi', 'name');
    is($lookup->nickname, 'tashikani', 'nickname');

    $lookup->name( 'name' );
    $lookup->nickname( 'nickname' );
    $lookup->update;

    my($get) = $model->get( model => 'kristate' );
    is($get->id, 'kristate', 'id');
    is($get->name, 'name', 'name');
    is($get->nickname, 'nickname', 'nickname');

    ok($get->delete, 'deleted');
}

