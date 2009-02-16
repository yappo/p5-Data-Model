package Mock::Basic;
use strict;
use warnings;
use base 'Data::Model';
use Data::Model::Schema;

install_model user => schema {
    driver $main::DRIVER;
    key 'id';
    columns qw/id name/;
};

install_model bookmark => schema {
    driver $main::DRIVER;
    key 'id';
    unique 'url';

    column id
        => int => {
            auto_increment => 1,
        };

    column 'url';
};

install_model bookmark_user => schema {
    driver $main::DRIVER;
    key [qw/ bookmark_id user_id /];
    index 'user_id';

    column bookmark_id
        => char => {
            size => 100,
        };
    column user_id
        => char => {
            size => 100,
        };
};

1;
