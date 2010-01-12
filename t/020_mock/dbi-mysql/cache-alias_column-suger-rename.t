use t::Utils config => +{
    type   => 'AliasColumnSugerRename',
    driver => 'DBI',
    dsn    => 'dbi:mysql:database=test',
    cache  => 'HASH',
};
run;
