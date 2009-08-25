use t::Utils config => +{
    type   => 'Iterator',
    driver => 'DBI',
    dsn    => 'dbi:mysql:database=test',
};
run;
