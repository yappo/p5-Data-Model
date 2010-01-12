use t::Utils config => +{
    type   => 'Index',
    driver => 'Memory',
    cache  => 'Memcached',
};
run;
