package Mixin::Basic;
use strict;
use warnings;

sub register_method {
    +{
        basic => \&basic,
    };
}

sub basic { 'mixin_basic', @_ }

1;

