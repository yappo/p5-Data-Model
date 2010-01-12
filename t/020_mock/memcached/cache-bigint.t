use t::Utils config => +{
    type   => 'Bigint',
    driver => 'Memcached',
    cache  => 'HASH',
};
run;
