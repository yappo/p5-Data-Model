use t::Utils config => +{
    type   => 'InflateColumnSuger',
    driver => 'DBI',
    dsn    => 'dbi:SQLite:dbname=',
    cache  => 'Memcached',
};
run;
