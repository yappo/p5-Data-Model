package Data::Model::Iterator;
use strict;
use warnings;
use overload
    '<>' => sub { shift->next },
    fallback => 1;

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

sub has_next {
    my $self = shift;
    my $obj = $self->next;
    $self->{count}--;
    !!$obj;
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
    '<>'   => sub { shift->next },
    fallback => 1;

sub new { bless {}, shift }
sub has_next { 0 }
sub next  { undef }
sub reset { undef }
sub end   { undef }

1;
__END__

=head1 NAME

Data::Model::Iterator - Data::Model's iteration class

=head1 SYNOPSIS

  use Data::Model::Iterator;

  my @stack = qw( 1 2 );
  my $itr = Data::Model::Iterator->new(
      sub { ok(1, 'do shift'); shift @stack },
      end   => sub { ok(1, 'do end') },
      reset => sub { ok(1, 'do reset') },
  );

  #
  Dump($itr->next) if $itr->has_next;

  # iteration
  while (my $row = $itr->next) {
      say $row;
      # some code
  }

  while (<$itr>) {
      say $_;
      # some code
  }

  while (my $row = <$itr>) {
      say $row;
      # some code
  }

for empty iteration

  my $itr = Data::Model::Iterator::Empty->new;
  return unless $itr; # bool overload
  return unless $itr->has_next;

=head1 METHODS

=head2 has_next

=head2 next

=head2 reset

=head1 SEE ALSO

L<overload>

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo <at> shibuya <döt> plE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

