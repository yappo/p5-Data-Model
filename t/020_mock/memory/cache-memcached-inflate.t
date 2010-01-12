use t::Utils config => +{
    type   => 'Inflate',
    driver => 'Memory',
    cache  => 'Memcached',
};
run;
