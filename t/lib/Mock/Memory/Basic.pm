package Mock::Memory::Basic;
use strict;
use warnings;
use base 'Data::Model';
use Data::Model::Schema;
use Data::Model::Driver::Memory;

my $memory = Data::Model::Driver::Memory->new;

install_model user => schema {
    driver $memory;
    key 'id';
    columns qw/id name/;
};

install_model bookmark => schema {
    driver $memory;
    key 'id';

    column id
        => int => {
            auto_increment => 1,
        };

    column 'url';
};

install_model bookmark_user => schema {
    my $columns = [qw/ bookmark_id user_id /];
    driver $memory;
    key $columns;
    columns @{ $columns };
    index 'user_id';
};

1;

# validation
