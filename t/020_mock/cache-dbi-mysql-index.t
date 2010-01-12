use t::Utils config => +{
    type   => 'Index',
    driver => 'DBI',
    dsn    => 'dbi:mysql:database=test',
    cache  => 'HASH',
};
run;
