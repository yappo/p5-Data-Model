# storaged to memcache protocol (not for cache)
package Data::Model::Driver::Memcached;
use strict;
use warnings;
use base 'Data::Model::Driver';

use Carp ();

sub memcached { shift->{memcached} }

sub update_direct { Carp::croak("update_direct is NOT IMPLEMENTED") }

sub lookup {
    my($self, $schema, $key) = @_;
    my $cache_key = $self->cache_key($schema, $key);
    my $ret = $self->{memcached}->get( $cache_key );
    return unless $ret;
    return $ret;
}

sub lookup_multi {
    my($self, $schema, $keys) = @_;
    my @cache_keys = map { $self->cache_key($schema, $_) } @{ $keys };
    my $ret = $self->{memcached}->get_multi( @cache_keys );
    return unless $ret;

    my %resultlist;
    while (my($id, $data) = each %{ $ret }) {
        my $key = $schema->get_key_array_by_hash($data);
        $resultlist{join "\0", @{ $key }} = +{ %{ $data } };
    }
    return \%resultlist;
}

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

