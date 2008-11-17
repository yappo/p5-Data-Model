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
    my $columns = [qw/ bookmark_id user_id /];
    driver $main::DRIVER;
    key $columns;
    index 'user_id';

    columns @{ $columns };
};

1;
