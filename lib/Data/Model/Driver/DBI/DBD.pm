package Data::Model::Driver::DBI::DBD;
use strict;
use warnings;

sub new {
    my($class, $dbd, %args) = @_;
    my $dbd_class = "$class\::$dbd";
    eval "use $dbd_class;"; ## no critic
    die $@ if $@;
    bless { %args }, $dbd_class;
}

sub fetch_last_id {}
sub bind_param_attributes {}

1;
