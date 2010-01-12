use t::Utils config => +{
    type   => 'Bigint',
    driver => 'DBI',
    dsn    => 'dbi:mysql:database=test',
    cache  => 'HASH',
};
run;
