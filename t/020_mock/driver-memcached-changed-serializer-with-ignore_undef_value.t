use t::Utils config => +{
    type   => 'DriverMemcached',
    driver => 'Memcached',
    driver_config => {
        serializer         => 'Default',
        ignore_undef_value => 1,
    },
};
run;
