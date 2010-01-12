use t::Utils config => +{
    type   => 'AliasColumn',
    driver => 'Memory',
    cache  => 'Memcached',
};
run;
