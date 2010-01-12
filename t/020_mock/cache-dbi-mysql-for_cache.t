use t::Utils config => +{
    type   => 'ForCache',
    driver => 'DBI',
    dsn    => 'dbi:mysql:database=test',
    cache  => 'HASH',
};
run;
