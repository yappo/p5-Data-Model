package Data::Model::Extend::Queue::Q4M;
use strict;
use warnings;
use base 'Data::Model';

use Carp ();

sub queue_running {
    my $self = $_[0];
    my $driver = $self->get_base_driver;
    Carp::croak "Can't find base_driver" unless $driver;

    local $Carp::CarpLevel = 2;
    $driver->queue_running( @_ );
}

1;


