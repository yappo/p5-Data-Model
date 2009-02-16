package Mock::NoKey;
use strict;
use warnings;
use base 'Data::Model';
use Data::Model::Schema;


install_model not_key => schema {
    driver $main::DRIVER;
    columns qw( c_int1 c_int2 c_char1 );
};

1;
