package Mock::Iterator;
use strict;
use warnings;
use base 'Data::Model';
use Data::Model::Schema;

install_model user => schema {
    driver $main::DRIVER;
    key 'foo';
    column 'foo';
};

1;
