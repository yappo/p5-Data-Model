BEGIN{ $ENV{TEST_COLUMN_RENAME} = 1 };
use t::Utils config => +{
    type   => 'DriverMemcached',
    driver => 'Memcached',
};
run;
