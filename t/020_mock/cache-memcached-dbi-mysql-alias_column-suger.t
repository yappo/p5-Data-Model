use t::Utils config => +{
    type   => 'AliasColumnSuger',
    driver => 'DBI',
    dsn    => 'dbi:mysql:database=test',
    cache  => 'Memcached',
};
run;
