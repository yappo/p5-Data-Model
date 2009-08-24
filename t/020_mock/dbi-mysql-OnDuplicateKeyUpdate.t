use t::Utils config => +{
    type   => 'OnDuplicateKeyUpdate',
    driver => 'DBI',
    dsn    => 'dbi:mysql:database=test',
};
run;
