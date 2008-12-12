use t::Utils config => +{
    type   => 'Default',
    driver => 'Memory',
    dsn    => 'dbi:SQLite:dbname=',
};
run;
