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
    key 'key';
    unique unq => [@columns];
    column key
        => 'int' => { auto_increment => 1 };
    columns @columns;
};

install_model multi_index => schema {
    my @columns = qw( idx1 idx2 idx3 );
    driver $main::DRIVER;
    key 'key';
    index idx => [@columns];
    column key
        => 'int' => { auto_increment => 1 };
    columns @columns;
};

sub as_sqls {
    [
        "CREATE TABLE multi_keys ( key1 CHAR(255), key2 CHAR(255), key3 CHAR(255), PRIMARY KEY(key1, key2, key3) )",
        "CREATE TABLE multi_unique ( key INTEGER NOT NULL PRIMARY KEY, unq1 CHAR(255), unq2 CHAR(255), unq3 CHAR(255), UNIQUE (unq1, unq2, unq3) )",
        "CREATE TABLE multi_index ( key INTEGER NOT NULL PRIMARY KEY, idx1 CHAR(255), idx2 CHAR(255), idx3 CHAR(255) )",
        "CREATE INDEX idx ON multi_index(idx1, idx2, idx3)",
    ];
}

1;
