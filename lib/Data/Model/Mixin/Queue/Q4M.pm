package Data::Model::Mixin::Queue::Q4M;
use strict;
use warnings;

use Carp ();

sub register_method {
    +{
        queue_running => \&queue_running,
    };
}

sub queue_running {
    my $self = $_[0];
    my $driver = $self->get_base_driver;
    Carp::croak "Can't find base_driver" unless $driver;

    local $Carp::CarpLevel = 2;
    $driver->queue_running( @_ );
}

1;
