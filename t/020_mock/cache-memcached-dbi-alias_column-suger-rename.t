use t::Utils config => +{
    type   => 'AliasColumnSugerRename',
    driver => 'DBI',
    dsn    => 'dbi:SQLite:dbname=',
    cache  => 'Memcached',
};
run;
