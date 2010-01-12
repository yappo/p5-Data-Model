use t::Utils config => +{
    type   => 'Inflate',
    driver => 'DBI',
    dsn    => 'dbi:SQLite:dbname=',
};
run;
