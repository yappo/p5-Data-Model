use t::Utils config => +{
    type   => 'AliasColumn',
    driver => 'Memory',
    cache  => 'HASH',
};
run;
