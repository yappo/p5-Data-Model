use t::Utils config => +{
    type   => 'DriverMemcached',
    driver => 'Memcached',
    cache  => 'HASH',
};
run;
