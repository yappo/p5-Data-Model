use t::Utils config => +{
    type   => 'Index',
    driver => 'Memory',
    cache  => 'HASH',
};
run;
