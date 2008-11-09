package t::Utils;
use strict;
use warnings;
use Path::Class;
use lib Path::Class::Dir->new('t', 'lib')->stringify;

sub import {
    my($class, %args) = @_;
    my $caller = caller;

    strict->import;
    warnings->import;

}

1;
