package Mock::Index;
use strict;
use warnings;
use base 'Data::Model';
use Data::Model::Schema;


install_model multi_keys => schema {
    my @columns = qw( key1 key2 key3 );
    driver $main::DRIVER;
    key [@columns];
    columns @columns;
};

install_model multi_unique => schema {
    my @columns = qw( unq1 unq2 unq3 );
    driver $main::DRIVER;
    key 'c_key';
    unique unq => [@columns];
    column c_key
        => 'int' => { auto_increment => 1 };
    columns @columns;
};

install_model multi_index => schema {
    my @columns = qw( idx1 idx2 idx3 );
    driver $main::DRIVER;
    key 'c_key';
    index idx => [@columns];
    column c_key
        => 'int' => { auto_increment => 1 };
    columns @columns;
};

1;
