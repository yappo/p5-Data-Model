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
    my $ret = $self->{memcached}->get( $memcached_key );
    return unless $ret;

    return $self->_generate_result_iterator([ $ret ]), +{};
}

sub set {
    my($self, $schema, $key, $columns, %args) = @_;

    my $memcached_key = $self->memcached_key($schema, $key);
    my $ret = $self->{memcached}->add( $memcached_key, $columns );
   return unless $ret;

    $columns;
}

sub replace {
    my($self, $schema, $key, $columns, %args) = @_;

    my $memcached_key = $self->memcached_key($schema, $key);
    my $ret = $self->{memcached}->set( $memcached_key, $columns );
    return unless $ret;

    $columns;
}

sub update {
    my($self, $schema, $old_key, $key, $old_columns, $columns, $changed_columns, %args) = @_;

    my $old_memcached_key = $self->memcached_key($schema, $old_key);
    my $new_memcached_key = $self->memcached_key($schema, $key);
    unless ($old_memcached_key eq $new_memcached_key) {
        my $ret = $self->delete($schema, $old_key);
        return unless $ret;
    }

    my $ret = $self->{memcached}->set( $new_memcached_key, $columns );
    return unless $ret;

    $columns;
}

sub delete {
    my($self, $schema, $key, $columns, %args) = @_;
    my $memcached_key = $self->memcached_key($schema, $key);
    my $data = $self->{memcached}->get( $memcached_key );
    return unless $data;
    my $ret = $self->{memcached}->delete( $memcached_key );
    return unless $ret;
    $data;
}

1;

