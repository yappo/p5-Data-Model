package Mock::Bigint;
use strict;
use warnings;
use base 'Data::Model';
use Data::Model::Schema;

install_model simple => schema {
    driver $main::DRIVER;
    key 'k';
    column 'k';
    column i => bigint => {};
};

1;
