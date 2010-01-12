use t::Utils config => +{
    type   => 'ForCache',
    driver => 'Memory',
    cache  => 'HASH',
};
run;
