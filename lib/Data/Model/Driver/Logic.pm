package Data::Model::Driver::Logic;
use strict;
use warnings;
use base 'Data::Model::Driver';

sub init {}
sub init_model {}

sub get {
    my $self   = shift;
    my $schema = shift;
    my $obj = $schema->{schema_obj};

    my $method = 'get_' . $schema->{model};
    my @ret = $obj->$method($schema, @_);
    $ret[1] = +{};
    if (ref($ret[0]) eq 'CODE') {
        return @ret;
    } elsif (ref($ret[0]) eq 'ARRAY') {
        return $self->_generate_result_iterator($ret[0]), $ret[1];
    } else {
        return $self->_generate_result_iterator([ $ret[0] ]), $ret[1];
    }
}

sub set {
    my $self   = shift;
    my $schema = shift;
    my $obj = $schema->{schema_obj};
    my $method = 'set_' . $schema->{model};
    return $obj->$method($schema, @_);
}

sub delete {
    my $self   = shift;
    my $schema = shift;
    my $obj = $schema->{schema_obj};
    my $method = 'delete_' . $schema->{model};
    return $obj->$method($schema, @_);
}

1;
