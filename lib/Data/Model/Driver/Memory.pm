package Data::Model::Driver::Memory;
use strict;
use warnings;
use base 'Data::Model::Driver';


## data loader

sub _load_data {
    my($self, $model, $type, $name) = @_;

    $self->{models}->{$model} ||= +{};
    if ($type eq 'data') {
        return +{
            records   => +{},
            seq       => 0,
            record_id => 0,
        };
    } else {
        return +{
            key     => +{},
            prefix  => +{},
        };
    }
}

sub load_data {
    my($self, $schema) = @_;
    $self->{models}->{$schema->{model}}->{data} ||= $self->_load_data($schema->{model}, 'data');
}

sub load_key {
    my($self, $schema) = @_;
    $self->{models}->{$schema->{model}}->{key} ||= $self->_load_data($schema->{model}, 'key');
}

sub load_index {
    my($self, $schema, $name) = @_;
    $self->{models}->{$schema->{model}}->{index}->{$name} ||= $self->_load_data($schema->{model}, 'index', $name);
}

sub load_unique {
    my($self, $schema, $name) = @_;
    $self->{models}->{$schema->{model}}->{unique}->{$name} ||= $self->_load_data($schema->{model}, 'unique', $name);
}

sub new {
    my $class = shift;
    bless {
        models => +{},
    }, $class;
}

sub save {}

sub generate_record_id {
    my($self, $schema) = @_;
    my $data = $self->load_data($schema);
    ++($data->{record_id});
}

## get, set, delete

sub get {
    my($self, $schema, $key, $columns, %args) = @_;

    # fetch record id
    my $result_id_list = $self->get_record_id_list($schema, $key, $columns);
    return unless $result_id_list && @{ $result_id_list };

    my $results = $self->get_result_list($schema, $columns, $result_id_list);
    return unless $results && @{ $results };

    $results = [ map { $_->[1] } @{ $results } ];
    $self->_generate_result_iterator($results);
}

sub set {
    my($self, $schema, $key, $columns, %args) = @_;

    # initilaize

    # check unique

    # delete old record

    # record_id
    my $record_id = $self->generate_record_id($schema);

    # write to index, key and unique
    $self->set_memory_index($schema, $key, $columns, $record_id);


    # write data
    my $data = $self->load_data($schema);
    $data->{records}->{$record_id} = $columns;
}

sub delete {
    my($self, $schema, $key, $columns, %args) = @_;

    # fetch record id
    my $result_id_list = $self->get_record_id_list($schema, $key, $columns);
    return unless $result_id_list && @{ $result_id_list };

    my $results = $self->get_result_list($schema, $columns, $result_id_list);
    return unless $results && @{ $results };

    # delete data
    my $data = $self->load_data($schema);
    my @deleted;
    for my $id ( map { $_->[0] } @{ $results }) {
        # write to index, key and unique
        $self->delete_memory_index($schema, $key, $data->{records}->{$id}, $id);

        my $del = delete $data->{records}->{$id};
        push @deleted, $del if $del;
    }

    return @deleted ? [ @deleted ] : undef;
}

## for memory index

sub get_record_id_list {
    my($self, $schema, $key, $columns) = @_;

    my $result_id_list = [];
    if ($key) {
        $result_id_list = $self->get_memory_index($schema, 'key', undef, $key);
    } else {
        # hash
        if (exists $columns->{index} && ref($columns->{index}) eq 'HASH') {
            my($index, $index_key) = %{ $columns->{index} };
            $index_key = [ $index_key ] unless ref($index_key);
            for my $index_type (qw/ unique index /) {
                if (exists $schema->{$index_type}->{$index}) {
                    $result_id_list = $self->get_memory_index($schema, $index_type, $index, $index_key);
                    last;
                }
            }
        }
    }
    $result_id_list;
}

sub get_memory_index {
    my($self, $schema, $index_type, $index, $key) = @_;
    my $columns = $index_type eq 'key' ? $schema->{key} : $schema->{$index_type}->{$index};

    my $method   = "load_$index_type";
    my $key_hash = $self->$method($schema, $index);
    my $key_data = $self->_generate_key_data($key);

    my $type = scalar(@{ $key }) == scalar(@{ $columns }) ? 'key' : 'prefix';
    my $result = $key_hash->{$type}->{$key_data};
    $result ? ref($result) ? [ keys %{ $result } ] : [ $result ] : [];
}

sub set_memory_index {
    my($self, $schema, $key, $columns, $id) = @_;
    $self->_set_memory_index($schema, 'key', undef, $key, $id);

    for my $index_type (qw/ unique index /) {
        for my $index (keys %{ $schema->{$index_type} }) {
            my @index_key = map {
                $columns->{$_}
            } @{ $schema->{$index_type}->{$index} };
            $self->_set_memory_index($schema, $index_type, $index, [ @index_key ], $id);
        }
    }
}

sub _set_memory_index {
    my($self, $schema, $index_type, $index, $key, $id) = @_;
    my $columns = $index_type eq 'key' ? $schema->{key} : $schema->{$index_type}->{$index};

    my $method   = "load_$index_type";
    my $key_hash = $self->$method($schema, $index);

    my @prefix = ();
    for my $k (@{ $key }) {
        push @prefix, $k;
        my $key_data = $self->_generate_key_data([ @prefix ]);

        my $type = scalar(@prefix) == scalar(@{ $key }) ? 'key' : 'prefix';
        my $hash = $key_hash->{$type};
        if (exists $hash->{$key_data}) {
            unless (ref($hash->{$key_data}) eq 'HASH') {
                my $oid = $hash->{$key_data};
                $hash->{$key_data} = +{
                    $oid => $oid,
                };
            }
            $hash->{$key_data}->{$id} = $id;
        } else {
            $hash->{$key_data} = $id;
        }
    }
}

sub delete_memory_index {
    my($self, $schema, $key, $columns, $id) = @_;
    $self->_delete_memory_index($schema, 'key', undef, $key, $id);

    for my $index_type (qw/ unique index /) {
        for my $index (keys %{ $schema->{$index_type} }) {
            my @index_key = map {
                $columns->{$_}
            } @{ $schema->{$index_type}->{$index} };
            $self->_delete_memory_index($schema, $index_type, $index, [ @index_key ], $id);
        }
    }
}

sub _delete_memory_index {
    my($self, $schema, $index_type, $index, $key, $id) = @_;
    my $columns = $index_type eq 'key' ? $schema->{key} : $schema->{$index_type}->{$index};

    my $method   = "load_$index_type";
    my $key_hash = $self->$method($schema, $index);

    my @prefix = ();
    for my $k (@{ $key }) {
        push @prefix, $k;
        my $key_data = $self->_generate_key_data([ @prefix ]);

        my $type = scalar(@prefix) == scalar(@{ $key }) ? 'key' : 'prefix';
        my $hash = $key_hash->{$type};
        if (ref($hash->{$key_data}) eq 'HASH') {
            delete $hash->{$key_data}->{$id};
            if (keys(%{ $hash->{$key_data} }) == 1) {
                my($k) = keys %{ $hash->{$key_data} };
                $hash->{$key_data} = $k;
            }
        } else {
            delete $hash->{$key_data};
        }
    }
}

# grep, sort, limit

sub get_result_list {
    my($self, $schema, $query, $id_list) = @_;

    # merge data
    my $data = $self->load_data($schema);
    my $results = [];
    for my $id (@ { $id_list }) {
        push @{ $results }, [ $id => $data->{records}->{$id} ];
    }

    $self->limit($schema, $query, $self->sort($schema, $query, $self->grep($schema, $query, $results)));
}

sub grep {
    my($self, $schema, $query, $rows) = @_;
    return $rows unless exists $query->{where};
}

sub sort {
    my($self, $schema, $query, $rows) = @_;
    $rows unless exists $query->{order};
}

sub limit {
    my($self, $schema, $query, $rows) = @_;
    return $rows unless exists $query->{limit} || exists $query->{offset};
}

1;
