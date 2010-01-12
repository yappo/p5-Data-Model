use t::Utils config => +{
    type   => 'NoKey',
    driver => 'DBI',
    dsn    => 'dbi:mysql:database=test',
    cache  => 'HASH',
};
run;
