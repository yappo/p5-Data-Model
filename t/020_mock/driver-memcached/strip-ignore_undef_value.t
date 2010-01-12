use t::Utils config => +{
    type   => 'DriverMemcached',
    driver => 'Memcached',
    driver_config => {
        strip_keys => 1,
        ignore_undef_value => 1,
    },
};
run;
