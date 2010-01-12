use t::Utils config => +{
    type   => 'Bigint',
    driver => 'Memcached',
};
run;
