package Mock::NoKey;
use strict;
use warnings;
use base 'Data::Model';
use Data::Model::Schema;


install_model not_key => schema {
    driver $main::DRIVER;
    columns qw( int1 int2 char1 );
};

1;
