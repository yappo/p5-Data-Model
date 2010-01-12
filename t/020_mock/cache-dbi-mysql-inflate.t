use t::Utils config => +{
    type   => 'Inflate',
    driver => 'DBI',
    dsn    => 'dbi:mysql:database=test',
    cache  => 'HASH',
};
run;
