package Data::Model::Mixin::FindOrCreate;
use strict;
use warnings;

sub register_method {
    +{
        find_or_create => \&find_or_create,
    };
}

sub find_or_create {
    my($self, $model, $key, $columns) = @_;
    my $row = $self->lookup( $model => $key );
    return $row if $row;

    $self->set( $model => $key => $columns );
}

1;

=head1 NAME

Data::Model::Mixin::FindOrCreate - add find_or_create method

=head1 SYNOPSIS

  use Data::Model::Mixin modules => ['FindOrCreate'];

  $model->find_or_create(
      tablename => key => {
          field1 => 'value',
          field2 => 'value',
      }
  );

  $model->find_or_create(
      tablename => [qw/ key1 key2 /] => {
          field1 => 'value',
          field2 => 'value',
      }
  );

=cut

