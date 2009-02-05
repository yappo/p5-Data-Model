use t::Utils config => +{
    type   => 'AliasColumnSuger',
    driver => 'Memory',
    cache  => 'HASH',
};
run;
