use t::Utils config => +{
    type   => 'Binary',
    driver => 'Memory',
    cache  => 'Memcached',
};
run;
