use t::Utils config => +{
    type   => 'AliasColumnSuger',
    driver => 'DBI',
    dsn    => 'dbi:SQLite:dbname=',
    cache  => 'HASH',
};
run;
