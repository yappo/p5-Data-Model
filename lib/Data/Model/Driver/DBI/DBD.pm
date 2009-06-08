package Data::Model::Driver::DBI::DBD;
use strict;
use warnings;

use Carp ();
$Carp::Internal{(__PACKAGE__)}++;

sub new {
    my($class, $dbd, %args) = @_;
    my $dbd_class = "$class\::$dbd";
    eval "use $dbd_class;"; ## no critic
    Carp::croak $@ if $@;
    bless { %args }, $dbd_class;
}

sub fetch_last_id {}
sub bind_param_attributes {}
sub can_replace { 1 }

sub _as_sql_hook {
    my $self   = shift;
    my $c      = shift;
    my $method = shift;

    $method =~ s/^as_//;
    if (my $code = $self->can("_as_sql_$method")) {
        return $code->($self, $c, @_);
    }
    return;
}

1;
