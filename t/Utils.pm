package t::Utils;
use strict;
use warnings;
use File::Temp ();
use DBI;
use Path::Class;
use lib Path::Class::Dir->new('t', 'lib')->stringify;

use IO::Socket::INET;
use Test::More;

sub import {
    my($class, %args) = @_;
    my $caller = caller;

    strict->import;
    warnings->import;

    for my $name (qw/ temp_filename run setup_schema teardown_schema /) {
        no strict 'refs';
        *{"$caller\::$name"} = \&{$name};
    }

    if ($args{config}) {
        $class->setup_test($caller, $args{config});
    }
}

my $RUN_CODE = sub {};
my $CLEANUP_CODE = sub {};
my $CACHE_CLASS;
sub _make_driver_instance {
    my $class = shift;
    my $driver = $class->new( @_ );

    if ($CACHE_CLASS) {
        my %options = ();
        if ($CACHE_CLASS =~ /::Memcached$/) {
            my $memcached_bin     = $ENV{TEST_MEMCACHED_BIN};

            eval "use Cache::Memcached::Fast";
            plan skip_all => "Cache::Memcached::Fast required for testing memcached driver" if $@;

            if ($memcached_bin && -x $memcached_bin) {

                eval "use Test::TCP";
                plan skip_all => "Test::TCP required for testing memcached driver" if $@;

                my $port = empty_port();
                $options{memcached} = Cache::Memcached::Fast->new({ servers => [ { address => "localhost:$port" }, ], });

                my $run = $RUN_CODE;
                $RUN_CODE = sub {
                    test_tcp(
                        client => sub {
                            $run->();
                        },
                        server => sub {
                            exec $memcached_bin, '-p', $port;
                        },
                        port => $port,
                    );
                };
            } else {
                plan skip_all => "Set TEST_MEMCACHED_BIN environment variable to run this test";
            }
        }
        $driver = $CACHE_CLASS->new(
            fallback => $driver,
            %options,
        );
    }
    $driver;
}

sub setup_test {
    my($class, $caller, $config) = @_;

    my $test   = "Mock::Tests::$config->{type}";
    my $driver = "Data::Model::Driver::$config->{driver}";
    eval "
    use Mock::Tests::$config->{type};
    use $driver;
    ";
    $@ && die $@;

    my $mock   = "Mock::$config->{type}";
    $RUN_CODE = sub {
        my $mock = $mock->new;
        $test->set_mock($mock);
        $test->runtests;
    };

    if (my $cache = $config->{cache}) {
        # use cache
        $CACHE_CLASS = "Data::Model::Driver::Cache::$cache";
        eval "use $CACHE_CLASS"; $@ and die $@;
    }

    my $dsn = $config->{dsn} || '';
    if ($dsn =~ /mysql/) {
        plan skip_all => "Set TEST_MYSQL environment variable to run this test"
            unless $ENV{TEST_MYSQL};
        eval "use DBD::mysql";
        plan skip_all => "DBD::mysql required for testing DBI mysql driver" if $@;
    }

    if ($dsn || $config->{driver} eq 'Memory') {
        if ($dsn =~ /sqlite/i) {
            my $dbfile = temp_filename();
            $dsn .= $dbfile;
        }

        $main::DRIVER = _make_driver_instance(
            $driver,
            dsn => $dsn,
            username => $config->{username} || '',
            password => $config->{password} || '',
            %{ $config->{driver_config} },
        );
        eval "use $mock"; $@ and die $@;

        if ($dsn =~ /mysql/i) {
            $CLEANUP_CODE = sub {
                my $dbh = DBI->connect($dsn,
                                       '', '', { RaiseError => 1, PrintError => 0 });
                for my $table ($mock->schema_names) {
                    eval { $dbh->do( "DROP TABLE $table" ) };
                }
            };
            $CLEANUP_CODE->();
        }
        if ($dsn =~ /sqlite|mysql/i) {
            setup_schema( $dsn => $mock->as_sqls );
        }
    } elsif ($config->{driver} eq 'Memcached') {
        my $memcached_address = $ENV{TEST_MEMCACHED_ADDRESS};
        my $memcached_bin     = $ENV{TEST_MEMCACHED_BIN};

        eval "use Cache::Memcached::Fast";
        plan skip_all => "Cache::Memcached::Fast required for testing memcached driver" if $@;

        if ($memcached_bin && -x $memcached_bin) {

            eval "use Test::TCP";
            plan skip_all => "Test::TCP required for testing memcached driver" if $@;

            my $port = empty_port();
            $main::DRIVER = _make_driver_instance(
                $driver,
                memcached => Cache::Memcached::Fast->new({ servers => [ { address => "localhost:$port" }, ], }),
                %{ $config->{driver_config} },
            );

            eval "use $mock"; $@ and die $@;

            my $run = $RUN_CODE;
            $RUN_CODE = sub {
                test_tcp(
                    client => sub {
                        $run->();
                        $CLEANUP_CODE->();
                    },
                    server => sub {
                        exec $memcached_bin, '-p', $port;
                    },
                    port => $port,
                );
            };

        } elsif ($memcached_address) {

            my(undef, $port) = split ':', $memcached_address;
            my $sock = IO::Socket::INET->new(
                Listen    => 5,
                LocalAddr => '127.0.0.1',
                LocalPort => $port,
                Proto     => 'tcp'
            );
            plan skip_all => 'can not running memcached server' if $sock;

            $main::DRIVER = _make_driver_instance(
                $driver,
                memcached => Cache::Memcached::Fast->new({ servers => [ { address => ($memcached_address || 'localhost:11211') }, ], }),
                %{ $config->{driver_config} },
            );

            eval "use $mock"; $@ and die $@;

        } else {
            plan skip_all => "Set TEST_MEMCACHED_ADDRESS or TEST_MEMCACHED_BIN environment variable to run this test";
        }

    }
}

sub run {
    $RUN_CODE->();
    $CLEANUP_CODE->();
}

sub temp_filename {
    my $fh = File::Temp->new;
    my $filename = $fh->filename;
    close $fh;
    $filename;
}

sub setup_schema {
    my($dsn, @sqls) = @_;
    my $dbh = ref($dsn) eq 'DBI::db' ? $dsn : DBI->connect($dsn,
                           '', '', { RaiseError => 1, PrintError => 0 });
    for my $sql (@sqls) {
        $dbh->do( $sql );
    }
    $dbh->disconnect;
}

sub teardown_schema {
    my($dsn, @tables) = @_;
    my $dbh = ref($dsn) eq 'DBI::db' ? $dsn : DBI->connect($dsn,
                           '', '', { RaiseError => 1, PrintError => 0 });
    for my $table (@tables) {
        eval { $dbh->do( "DROP TABLE IF EXISTS $table" ) };
    }
    $dbh->disconnect;
}


1;
