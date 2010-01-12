use strict;
use warnings;
use Path::Class;

for my $cache_name (qw/ cache cache-memcached none /) {
    my $cache = +{
        'cache'           => qq{    cache  => 'HASH',\n},
        'cache-memcached' => qq{    cache  => 'Memcached',\n},
        'none'            => '',
    }->{$cache_name};

    for my $driver_name (qw/ dbi dbi-mysql memory memcached /) {
        my $driver = +{
            'dbi'       => qq{    driver => 'DBI',\n    dsn    => 'dbi:SQLite:dbname=',\n},
            'dbi-mysql' => qq{    driver => 'DBI',\n    dsn    => 'dbi:mysql:database=test',\n},
            'memory'    => qq{    driver => 'Memory',\n},
            'memcached' => qq{    driver => 'Memcached',\n},
        }->{$driver_name};

        for my $test_type (qw/ alias_column-suger-rename alias_column-suger alias_column basic bigint binary default for_cache index inflate inflate_column-suger iterator no_key transaction/) {
            next if $driver_name eq 'memory' && $test_type eq 'transaction';
            if ($driver_name eq 'memcached') {
                next unless $test_type eq 'bigint';
            }

            my $type = +{
                'alias_column-suger-rename' => 'AliasColumnSugerRename',
                'alias_column-suger'        => 'AliasColumnSuger',
                'alias_column'              => 'AliasColumn',
                'basic'                     => 'Basic',
                'bigint'                    => 'Bigint',
                'binary'                    => 'Binary',
                'default'                   => 'Default',
                'for_cache'                 => 'ForCache',
                'index'                     => 'Index',
                'inflate'                   => 'Inflate',
                'inflate_column-suger'      => 'InflateColumnSuger',
                'iterator'                  => 'Iterator',
                'no_key'                    => 'NoKey',
                'transaction'               => 'Transaction',
            }->{$test_type};

            my $code = qq!use t::Utils config => +{
    type   => '$type',
$driver$cache};
run;
!;

            my $dir  = Path::Class::Dir->new(qw/ t 020_mock /, $driver_name);
            $dir->mkpath;
            my $name = ($cache_name eq 'none') ? '' : "$cache_name-";
            $name   .= "$test_type.t";
            my $fh = $dir->file($name)->openw;
            print $fh $code;
        }
    }
}

__END__
use t::Utils config => +{
    type   => 'Basic',
    driver => 'DBI',
    dsn    => 'dbi:SQLite:dbname=',
    cache  => 'HASH',
};
run;

