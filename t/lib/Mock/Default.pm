package Mock::Default;
use strict;
use warnings;
use base 'Data::Model';
use Data::Model::Schema;

install_model tbl => schema {
    driver $main::DRIVER;
    key 'id';

    column id
        => int => {
            auto_increment => 1,
        };

    column c_int1
        => int => {
            default => 10,
        };

    column c_char1
        => char => {
            default => 'foo',
        };

    column code1
        => char => {
            default => sub { 'bar' },
        };

};

1;

