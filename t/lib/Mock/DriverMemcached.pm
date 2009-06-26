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

    if ($ENV{TEST_COLUMN_RENAME}) {
        schema_options column_name_rename => {
            id       => 1,
            name     => 2,
        };
    }
    if ($ENV{TEST_MODEL_RENAME}) {
        schema_options model_name_realname => 's';
    }
};

install_model multi_keys => schema {
    my @columns = qw( key1 key2 key3 );
    driver $main::DRIVER;
    key [@columns];
    columns @columns;

    if ($ENV{TEST_COLUMN_RENAME}) {
        schema_options column_name_rename => {
            key1     => 1,
            key2     => 2,
            key3     => 3,
        };
    }
    if ($ENV{TEST_MODEL_RENAME}) {
        schema_options model_name_realname => 'mk';
    }
};

install_model multi_keys_columns => schema {
    my @columns = qw( key1 key2 key3 );
    driver $main::DRIVER;
    key [@columns];
    columns @columns, qw/ name nickname /;

    if ($ENV{TEST_COLUMN_RENAME}) {
        schema_options column_name_rename => {
            key1     => 1,
            key2     => 2,
            key3     => 3,
            name     => 4,
            nickname => 5,
        };
    }
    if ($ENV{TEST_MODEL_RENAME}) {
        schema_options model_name_realname => 'mkc';
    }
};

1;
