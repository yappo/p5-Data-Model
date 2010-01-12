use t::Utils config => +{
    type   => 'Transaction',
    driver => 'DBI',
    dsn    => 'dbi:SQLite:dbname=',
    cache  => 'HASH',
};
run;
