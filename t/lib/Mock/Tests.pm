package Mock::Tests;
use t::Utils;

sub import {
    my $class  = shift;
    my $caller = caller;
    for my $name (qw/ mock mock_class set_mock /) {
        no strict 'refs';
        *{"$caller\::$name"} = \&{$name};
    }
}

my $mock;
my $mock_class;
sub set_mock {
    $mock = $_[1];
    $mock_class = ref($mock);
}
sub mock { $mock }
sub mock_class { $mock_class }

1;
