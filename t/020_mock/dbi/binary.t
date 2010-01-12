use t::Utils config => +{
    type   => 'Binary',
    driver => 'DBI',
    dsn    => 'dbi:SQLite:dbname=',
};
run;
