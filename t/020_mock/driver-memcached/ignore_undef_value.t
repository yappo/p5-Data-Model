use t::Utils config => +{
    type   => 'DriverMemcached',
    driver => 'Memcached',
    driver_config => {
        ignore_undef_value => 1,
    },
};
run;
