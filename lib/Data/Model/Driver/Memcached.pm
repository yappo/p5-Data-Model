# storaged to memcache protocol (not for cache)
package Data::Model::Driver::Memcached;
use strict;
use warnings;
use base 'Data::Model::Driver';

use Carp ();

sub memcached { shift->{memcached} }

sub update_direct { Carp::croak("update_direct is NOT IMPLEMENTED") }

sub get {
    my($self, $schema, $key, $columns, %args) = @_;

    my $cache_key = $self->cache_key($schema, $key);
    my $ret = $self->{memcached}->get( $cache_key );
    return unless $ret;

    return $self->_generate_result_iterator([ $ret ]), +{};
}

sub set {
    my($self, $schema, $key, $columns, %args) = @_;

    my $cache_key = $self->cache_key($schema, $key);
    my $ret = $self->{memcached}->add( $cache_key, $columns );
    return unless $ret;

    $columns;
}

sub replace {
    my($self, $schema, $key, $columns, %args) = @_;

    my $cache_key = $self->cache_key($schema, $key);
    my $ret = $self->{memcached}->set( $cache_key, $columns );
    return unless $ret;

    $columns;
}

sub update {
    my($self, $schema, $old_key, $key, $old_columns, $columns, $changed_columns, %args) = @_;

    my $old_cache_key = $self->cache_key($schema, $old_key);
    my $new_cache_key = $self->cache_key($schema, $key);
    unless ($old_cache_key eq $new_cache_key) {
        my $ret = $self->delete($schema, $old_key);
        return unless $ret;
    }

    my $ret = $self->{memcached}->set( $new_cache_key, $columns );
    return unless $ret;

    $columns;
}

sub delete {
    my($self, $schema, $key, $columns, %args) = @_;
    my $cache_key = $self->cache_key($schema, $key);
    my $data = $self->{memcached}->get( $cache_key );
    return unless $data;
    my $ret = $self->{memcached}->delete( $cache_key );
    return unless $ret;
    $data;
}

1;

