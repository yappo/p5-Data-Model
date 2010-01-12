use t::Utils config => +{
    type   => 'Bigint',
    driver => 'Memcached',
    cache  => 'Memcached',
};
run;
