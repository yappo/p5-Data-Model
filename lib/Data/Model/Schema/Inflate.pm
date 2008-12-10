package Data::Model::Schema::Inflate;
use strict;
use warnings;

use Carp ();

sub import {
    my $class  = shift;
    my $caller = caller;

    no strict 'refs';
    *{"$caller\::inflate_type"} = \&inflate_type;
}

my %INFLATE = (
    inflate => {
        URI => sub {
            URI->new(shift);
        },
    },
    deflate => {
        URI => sub {
            shift->as_string;
        },
    },
);

sub get_inflate {
    my($class, $name) = @_;
    $INFLATE{inflate}->{$name};
}

sub get_deflate {
    my($class, $name) = @_;
    $INFLATE{deflate}->{$name};
}

sub inflate_type {
    my($name, $hash) = @_;
    my $caller = caller;
    for my $type (qw/ inflate deflate /) {
        if (ref($hash->{$type}) eq 'CODE') {
            Carp::croak "The inflate_type '$name' has already been created, cannot be created again in $caller"
                    if $INFLATE{$type}->{$name};
            $INFLATE{$type}->{$name} = $hash->{$type};
        }
    }
}

1;
