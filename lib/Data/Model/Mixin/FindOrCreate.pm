package Data::Model::Mixin::FindOrCreate;
use strict;
use warnings;

use Carp ();

sub register_method {
    +{
        find_or_create => \&find_or_create,
    };
}

sub find_or_create {
    my($self, $model, $key, $columns) = @_;
    my $row;
    if (ref($key) eq 'HASH') {
        # use on unique index
        my($index, $value) = %{ $key };
        Carp::corak('index name is required') unless $index;

        my $schema = $self->get_schema($model);
        Carp::croak("'$index' is not unique index") unless $schema->unique->{$index};

        ($row) = $self->get($model, { index => { $index => $value } });
        return $row if $row;
        $self->set( $model => $columns );
    } else {
        # primary key

        $row = $self->lookup( $model => $key );
        return $row if $row;
        $self->set( $model => $key => $columns );
    }

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

  # using unique index, but not use normal index
  $model->find_or_create(
      tablename => { unique_idx => 'key' } => {
          field1 => 'value',
          field2 => 'value',
      }
  );

  $model->find_or_create(
      tablename => { unique_idx => [qw/ key1 key2 /] } => {
          field1 => 'value',
          field2 => 'value',
      }
  );

=cut

