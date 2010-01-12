use t::Utils config => +{
    type   => 'AliasColumnSugerRename',
    driver => 'Memory',
    cache  => 'HASH',
};
run;
