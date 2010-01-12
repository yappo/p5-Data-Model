use t::Utils config => +{
    type   => 'Default',
    driver => 'Memory',
    cache  => 'Memcached',
};
run;
