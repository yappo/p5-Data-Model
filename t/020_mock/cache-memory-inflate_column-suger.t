use t::Utils config => +{
    type   => 'InflateColumnSuger',
    driver => 'Memory',
    cache  => 'HASH',
};
run;
