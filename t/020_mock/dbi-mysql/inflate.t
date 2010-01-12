use t::Utils config => +{
    type   => 'Inflate',
    driver => 'DBI',
    dsn    => 'dbi:mysql:database=test',
};
run;
