# storaged to memcache protocol (not for cache)
package Data::Model::Driver::Memcached;
use strict;
use warnings;
use base 'Data::Model::Driver';

use Carp ();

sub memcached { shift->{memcached} }

sub memcached_key {
    my($self, $schema, $id) = @_;

    Carp::confess 'The number of key is wrong'
            unless scalar(@{ $id }) == scalar(@{ $schema->key });

    join ':', $schema->model, ref($id) eq 'ARRAY' ? @$id : $id;
}

sub update_direct { Carp::croak("update_direct is NOT IMPLEMENTED") }

sub get {
    my($self, $schema, $key, $columns, %args) = @_;

    my $memcached_key = $self->memcached_key($schema, $key);
    my $data = $self->{memcached}->get( $memcached_key );
    return unless $data;

    return $self->_generate_result_iterator([ $data ]), +{};
}

sub set {
    my($self, $schema, $key, $columns, %args) = @_;

    my $memcached_key = $self->memcached_key($schema, $key);
    $self->{memcached}->set( $memcached_key, $columns );

    $columns;
}

sub replace {
    my($self, $schema, $key, $columns, %args) = @_;
    $self->set($schema, $key, $columns, %args);
}

sub update {
    my($self, $schema, $old_key, $key, $old_columns, $columns, $changed_columns, %args) = @_;

    my $old_memcached_key = $self->memcached_key($schema, $old_key);
    my $new_memcached_key = $self->memcached_key($schema, $key);
    $self->delete($schema, $old_key) unless $old_memcached_key eq $new_memcached_key;

    $self->set($schema, $key, $columns, %args);
}

sub delete {
    my($self, $schema, $key, $columns, %args) = @_;
    my $memcached_key = $self->memcached_key($schema, $key);
    my $data = $self->{memcached}->get( $memcached_key );
    return unless $data;
    return unless $self->{memcached}->delete( $memcached_key );
    $data;
}

1;

