use t::Utils config => +{
    type   => 'NoKey',
    driver => 'Memory',
    cache  => 'Memcached',
};
run;
