package Mock::DriverMemcached;
use strict;
use warnings;
use base 'Data::Model';
use Data::Model::Schema;


install_model simple => schema {
    driver $main::DRIVER;
    key 'id';
    column 'id';
    column 'name';
};

install_model multi_keys => schema {
    my @columns = qw( key1 key2 key3 );
    driver $main::DRIVER;
    key [@columns];
    columns @columns;
};

install_model multi_keys_columns => schema {
    my @columns = qw( key1 key2 key3 );
    driver $main::DRIVER;
    key [@columns];
    columns @columns, qw/ name nickname /;
};

1;
