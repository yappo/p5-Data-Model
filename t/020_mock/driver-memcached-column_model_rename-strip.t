BEGIN{ $ENV{TEST_COLUMN_RENAME} = 1; $ENV{TEST_MODEL_RENAME} = 1 };
use t::Utils config => +{
    type   => 'DriverMemcached',
    driver => 'Memcached',
    driver_config => {
        strip_keys => 1,
    },
};
run;
