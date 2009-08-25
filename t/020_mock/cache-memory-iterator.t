use t::Utils config => +{
    type   => 'Iterator',
    driver => 'Memory',
    cache  => 'HASH',
};
run;
