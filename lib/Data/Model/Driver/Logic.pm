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
    return $self->_generate_result_iterator([ $obj->$method($schema, @_) ]), +{};
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
