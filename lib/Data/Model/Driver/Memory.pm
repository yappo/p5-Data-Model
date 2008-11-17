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

sub generate_auto_increment {
    my($self, $schema) = @_;
    my $data = $self->load_data($schema);
    ++($data->{seq});
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
    return $self->_generate_result_iterator($results), +{};
}

sub set {
    my($self, $schema, $key, $columns, %args) = @_;

    # initilaize

    # check unique
    if (@{ $schema->{key} } && grep { defined $_ } @{ $key }) {
        my $result_id_list = $self->get_record_id_list($schema, $key, +{});
        die 'not unique columns' if @{ $result_id_list };
    }
    if (scalar(%{ $schema->{unique} })) {
        while (my($unique_name, $unique_columns) = each %{ $schema->{unique} }) {
            my $index = [];
            for my $column (@{ $unique_columns }) {
                push @{ $index }, $columns->{$column};
            }
            my $result_id_list = $self->get_record_id_list($schema, undef, +{ index => { $unique_name => $ index } });
            die 'not unique columns' if @{ $result_id_list };
        }
    }

    # delete old record

    # record_id
    my $record_id = $self->generate_record_id($schema);

    # auto_increment
    if ($self->_set_auto_increment($schema, $columns, sub { $self->generate_auto_increment($schema) })) {
        # remake $key
        $key = $schema->{schema_obj}->get_key_array_by_hash($schema, $columns);
    }

    # write to index, key and unique
    $self->set_memory_index($schema, $key, $columns, $record_id);

    # write data
    my $data = $self->load_data($schema);
    $data->{records}->{$record_id} = +{ %{ $columns } };
}

sub replace {
    my($self, $schema, $key, $columns, %args) = @_;
    $self->delete($schema, $key, +{}, %args);
    $self->set($schema, $key, $columns, %args);
}

sub update {
    my($self, $schema, $old_key, $key, $old_columns, $columns, $changed_columns, %args) = @_;

    # fetch record id
    my $result_id_list = $self->get_record_id_list($schema, $old_key, +{});
    return unless $result_id_list && @{ $result_id_list };
    return if @{ $result_id_list } != 1; # not unique key
    my $id = $result_id_list->[0];

    # reindex
    $self->delete_memory_index($schema, $old_key, $old_columns, $id);
    $self->set_memory_index($schema, $key, $columns, $id);

    # set data
    my $data = $self->load_data($schema);
    $data->{records}->{$id} = +{ %{ $columns } };
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
        $columns ||= +{};
        if (exists $columns->{index} && ref($columns->{index}) eq 'HASH') {
            my($index, $index_key) = %{ $columns->{index} };
            $index_key = [ $index_key ] unless ref($index_key);
            for my $index_type (qw/ unique index /) {
                if (exists $schema->{$index_type}->{$index}) {
                    $result_id_list = $self->get_memory_index($schema, $index_type, $index, $index_key);
                    last;
                }
            }
        } else {
            my $data = $self->load_key($schema);
            $result_id_list = [
                values %{ $data->{key} }
            ];
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

    return $results unless $query && ref($query) eq 'HASH';
    return $self->limit($schema, $query, $self->sort($schema, $query, $self->grep($schema, $query, $results)));
}

sub grep {
    my($self, $schema, $query, $rows) = @_;
    return $rows unless exists $query->{where};
}

sub sort {
    my($self, $schema, $query, $rows) = @_;
    return $rows unless exists $query->{order};

    my $sort_data = [];
    for my $data (@{ $query->{order} }) {
        my($column, $vec) = (%{ $data });
        push @{ $sort_data }, +{
            column => $column,
            vec    => uc($vec),
            int    => !!($schema->{column}->{$column}->{type} =~ /int/i),
        };
    }

    my @ordered = sort {
        my $v = 0;
        for my $data (@{ $sort_data }) {
            my $column = $data->{column};
            if ($data->{int}) {
                next if $a->[1]->{$column} == $b->[1]->{$column};
                $v = $a->[1]->{$column} <=> $b->[1]->{$column};
            } else {
                next if $a->[1]->{$column} eq $b->[1]->{$column};
                $v = $a->[1]->{$column} cmp $b->[1]->{$column};
            }
            $v *= -1 if $data->{vec} eq 'DESC';
            last;
        }
        $v;
    } @{ $rows };
    \@ordered;
}

sub limit {
    my($self, $schema, $query, $rows) = @_;
    return $rows unless exists $query->{limit} || exists $query->{offset};

    my @limitted;
    if (exists $query->{offset}) {
        for (1..$query->{offset}) {
            shift @{ $rows };
        }
    }
    if (exists $query->{limit}) {
        for (1..$query->{limit}) {
            push @limitted, shift @{ $rows };
        }
    } else {
        push @limitted, @{ $rows };
    }
    return \@limitted;
}

1;
