use t::Utils config => +{
    type   => 'Default',
    driver => 'DBI',
    dsn    => 'dbi:SQLite:dbname=',
};
run;
