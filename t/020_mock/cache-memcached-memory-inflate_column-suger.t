use t::Utils config => +{
    type   => 'InflateColumnSuger',
    driver => 'Memory',
    cache  => 'Memcached',
};
run;
