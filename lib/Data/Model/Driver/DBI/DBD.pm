package Data::Model::Driver::DBI::DBD;
use strict;
use warnings;

sub new {
    my($class, $dbd, %args) = @_;
    my $dbd_class = "$class\::$dbd";
    eval "use $dbd_class;";
    die $@ if $@;
    bless { %args }, $dbd_class;
}

sub bind_param_attributes {}

1;
