use t::Utils config => +{
    type   => 'Basic',
    driver => 'Memory',
    cache  => 'Memcached',
};
run;
