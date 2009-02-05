package Mock::ForCache;
use strict;
use warnings;
use base 'Data::Model';
use Data::Model::Schema;

install_model user => schema {
    driver $main::DRIVER;
    key 'id';
    columns qw/id name/;
};

1;

