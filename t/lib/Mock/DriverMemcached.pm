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


install_model simple_rename => schema {
    driver $main::DRIVER;
    key 'id';
    column 'id';
    column 'name';

    schema_options column_name_rename => {
        id       => 1,
        name     => 2,
    };
};

install_model multi_keys_rename => schema {
    my @columns = qw( key1 key2 key3 );
    driver $main::DRIVER;
    key [@columns];
    columns @columns;

    schema_options column_name_rename => {
        key1     => 1,
        key2     => 2,
        key3     => 3,
    };
};

install_model multi_keys_columns_rename => schema {
    my @columns = qw( key1 key2 key3 );
    driver $main::DRIVER;
    key [@columns];
    columns @columns, qw/ name nickname /;

    schema_options column_name_rename => {
        key1     => 1,
        key2     => 2,
        key3     => 3,
        name     => 4,
        nickname => 5,
    };
};

1;
