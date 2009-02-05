package Data::Model::Driver::Cache::HASH;
use strict;
use warnings;
use base 'Data::Model::Driver::Cache';

my %CACHE;

sub add_to_cache {
    my($self, $key, $data) = @_;

    my $ret = $CACHE{$key} = $data;
    return if !defined $ret;
    return $ret;
}

sub get_from_cache {
    my($self, $key) = @_;

    my $ret = $CACHE{$key};
    return if !defined $ret;
    return $ret;
}

sub remove_from_cache {
    my($self, $key) = @_;
    
    my $ret = delete $CACHE{$key};
    return 1 if !defined $ret;
    return $ret;
}

1;

