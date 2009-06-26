BEGIN{ $ENV{TEST_MODEL_RENAME} = 1 };
use t::Utils config => +{
    type   => 'DriverMemcached',
    driver => 'Memcached',
    driver_config => {
        serializer => 'Default',
        strip_keys => 1,
    },
};
run;
