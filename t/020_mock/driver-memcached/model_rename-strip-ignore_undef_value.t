BEGIN{ $ENV{TEST_MODEL_RENAME} = 1 };
use t::Utils config => +{
    type   => 'DriverMemcached',
    driver => 'Memcached',
    driver_config => {
        strip_keys => 1,
        ignore_undef_value => 1,
    },
};
run;
