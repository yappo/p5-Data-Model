package Data::Model::Schema::Properties;
use strict;
use warnings;
use base qw(Data::Model::Accessor);

__PACKAGE__->mk_accessors(qw/ driver schema_class model class column index unique key options /);

sub new {
    my($class, %args) = @_;
    bless { %args }, $class;
}

sub add_keys {
    my($self, $key, %args) = @_;
    $self->{key} = ref($key) eq 'ARRAY' ? $key : [ $key ];
}

BEGIN {
    for my $name (qw/ unique index /) {
        no strict 'refs';
        *{"add_$name"} = sub {
            my($self, $index, $columns, %args) = @_;
            my $key = $columns || $index;
            die sprintf '%s::%s : %s name is require', $self->schema_class, $self->name, $name
                if ref($index) || !defined $index; 
            $key = [ $key ] unless ref($key) eq 'ARRAY';
            $self->{$name}->{$index} = $key;
        };
    }
}

sub add_column {
    my($self, $column, $type, $options) = @_;
    $self->{column}->{$column} = +{
        type    => $type    || 'char',
        options => $options || +{},
    };
}

sub add_options {
    my $self = shift;
    if (ref($_[0]) eq 'HASH') {
        $self->options(shift);
    } elsif (!(@_ % 2)) {
        while (my($key, $value) = splice @_, 0, 2) {
            $self->options->{$key} = $value;
        }
    }
}



sub column_names {
    my $self = shift;
    keys %{ $self->{column} };
}

sub column_type {
    my($self, $column) = @_;
    $self->{column}->{$column}->{type} || 'char';
}
sub column_options {
    my($self, $column) = @_;
    $self->{column}->{$column}->{options} || +{};
}



sub get_key_array_by_hash {
    my($self, $hash) = @_;
    my @keys;
    for my $key (@{ $self->{key} }) {
        push @keys, $hash->{$key};
    }
    \@keys;
}

sub get_columns_hash_by_key_array_and_hash {
    my($self, $hash, $array) = @_;
    my $ret = {};

    # by column
    for my $column (keys %{ $self->{column} }) {
        $ret->{$column} = $hash->{$column};
    }

    # by key
    my $key = $self->{key};
    $key = [ $key ] unless ref($key) eq 'ARRAY';
    @{ $ret }{@{ $key }} = @{ $array };

    $ret;
}

1;
