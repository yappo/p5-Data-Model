use t::Utils config => +{
    type   => 'Basic',
    driver => 'DBI',
    dsn    => 'dbi:mysql:database=test',
};
run;
