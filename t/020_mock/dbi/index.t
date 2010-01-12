use t::Utils config => +{
    type   => 'Index',
    driver => 'DBI',
    dsn    => 'dbi:SQLite:dbname=',
};
run;
