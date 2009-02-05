package Mock::SetBaseDriver;
use strict;
use warnings;
use base 'Data::Model';
use Data::Model::Schema;
use Data::Model::Driver::Memory;

base_driver(Data::Model::Driver::Memory->new);

install_model user => schema {
    key 'id';
    columns qw/id name/;
};

install_model bookmark => schema {
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
    key $columns;
    index 'user_id';

    columns @{ $columns };
};

1;
