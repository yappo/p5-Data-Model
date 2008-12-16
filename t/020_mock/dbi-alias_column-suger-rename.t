use t::Utils config => +{
    type   => 'AliasColumnSugerRename',
    driver => 'DBI',
    dsn    => 'dbi:SQLite:dbname=',
};
run;
