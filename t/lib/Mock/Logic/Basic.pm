package Mock::Logic::Basic;
use strict;
use warnings;
use base 'Data::Model';
use Data::Model::Schema;
use Data::Model::Driver::Logic;

my $logic = Data::Model::Driver::Logic->new;

model user => schema {
    driver $dbi;
    key 'id';
    columns qw/id name/;
};

sub get_user {}
sub set_user {}
sub update_user {}
sub delete_user {}

1;
