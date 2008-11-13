package Data::Model::Accessor;
use strict;
use warnings;

sub mk_accessors {
    my $class = shift;
    for my $field (@_) {
        no strict 'refs';
        *{"$class\::$field"} = sub {
            return $_[0]->{$field} unless @_ > 1;
            my $self = shift;
            $self->{$field} = (@_ == 1 ? $_[0] : [@_]);
        };
    }
}

1;
