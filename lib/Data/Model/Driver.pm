package Data::Model::Driver;
use strict;
use warnings;

sub new { 
    my($class, %args) = @_;
    my $self = bless { %args }, shift;
    $self->init;
    $self;
}

sub init {}
sub init_model {}

my $KEYSEPARATE = "\0";
sub _generate_key_data {
    my($self, $key_array) = @_;
    join $KEYSEPARATE, @{ $key_array };
}

sub _generate_result_iterator {
    my($self, $results) = @_;

    my $count = 0;
    my $max = scalar @{ $results };
    sub {
        my $reset = shift;
        $count = 0 if $reset;
        return unless $count < $max;
        $results->[$count++];
    };
}


sub get {}
sub set {}
sub delete {}

sub get_multi {}
sub set_multi {}
sub delete_multi {}

1;
