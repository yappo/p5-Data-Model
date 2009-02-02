package Data::Model::Schema::Inflate::UUID;
use strict;
use warnings;
use Data::Model::Schema::Inflate;
use Data::UUID;

our $GEN = Data::UUID->new;;

inflate_type UUID => {
    inflate => sub { $GEN->to_string( $_[0] ) },
    deflate => sub { $GEN->from_string( $_[0] ) },
};

1;

