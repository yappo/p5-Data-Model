package Data::Model::Iterator;
use strict;
use warnings;

sub new {
    my($class, $code, %args) = @_;
    bless {
        code    => $code,
        cache   => [],
        count   => 0,
        reset   => delete $args{reset}   || sub {},
        end     => delete $args{end}     || sub {},
        wrapper => delete $args{wrapper} || sub { shift },
    }, $class;
}

sub next {
    my $self = shift;
    $self->{cache}->[$self->{count}++] ||= do {
        my $obj = $self->{code}->();
        $obj ? $self->{wrapper}->( $obj ) : undef;
    };
}

sub reset {
    my $self = shift;
    $self->{count} = 0;
    $self->{reset}->();
}

sub end {
    my $self = shift;
    $self->{end}->();
}

sub DESTROY { shift->end };

package Data::Model::Iterator::Empty;
use strict;
use warnings;
use overload
    q{""}  => sub { undef },
    q{0+}  => sub { undef },
    'bool' => sub { undef },
    fallback => 1;

sub new { bless {}, shift }
sub next  { undef }
sub reset { undef }
sub end   { undef }

1;
