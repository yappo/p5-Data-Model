use t::Utils config => +{
    type   => 'Bigint',
    driver => 'Memory',
    cache  => 'Memcached',
};
run;
