package Mock::Binary;
use strict;
use warnings;
use base 'Data::Model';
use Data::Model::Schema;

install_model model => schema {
    driver $main::DRIVER;
    key 'id';

    column id
        => int => {
            auto_increment => 1,
        };
    column data
        => binary => {
            size => 8,
        };
};

install_model model_bin_id => schema {
    driver $main::DRIVER;
    key 'id';

    column id
        => binary => {
            size => 8,
        };
    column 'name';
};

1;
