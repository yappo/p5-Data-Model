package Data::Model::Mixin::Queue::Q4M;
use strict;
use warnings;

use Carp ();
$Carp::Internal{(__PACKAGE__)}++;

sub register_method {
    +{
        queue_running => \&queue_running,
    };
}

sub queue_running {
    my $self = $_[0];
    my $driver = $self->get_base_driver;
    Carp::croak "Can't find base_driver" unless $driver;

    $driver->queue_running( @_ );
}

1;

=head1 NAME

Data::Model::Mixin::Queue::Q4m - add methods for Driver::Queue::Q4M

=head1 SEE ALSO

L<Data::Model::Driver::Queue::Q4M>

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo <at> shibuya <döt> plE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
