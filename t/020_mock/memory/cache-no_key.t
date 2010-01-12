use t::Utils config => +{
    type   => 'NoKey',
    driver => 'Memory',
    cache  => 'HASH',
};
run;
