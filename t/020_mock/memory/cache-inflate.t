use t::Utils config => +{
    type   => 'Inflate',
    driver => 'Memory',
    cache  => 'HASH',
};
run;
