use t::Utils config => +{
    type   => 'AliasColumn',
    driver => 'DBI',
    dsn    => 'dbi:mysql:database=test',
    cache  => 'Memcached',
};
run;
