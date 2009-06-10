package Data::Model::Driver::Memory;
use strict;
use warnings;
use base 'Data::Model::Driver';

use Carp ();
$Carp::Internal{(__PACKAGE__)}++;

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
    $self->{models}->{$schema->model}->{data} ||= $self->_load_data($schema->model, 'data');
}

sub load_key {
    my($self, $schema) = @_;
    $self->{models}->{$schema->model}->{key} ||= $self->_load_data($schema->model, 'key');
}

sub load_index {
    my($self, $schema, $name) = @_;
    $self->{models}->{$schema->model}->{index}->{$name} ||= $self->_load_data($schema->model, 'index', $name);
}

sub load_unique {
    my($self, $schema, $name) = @_;
    $self->{models}->{$schema->model}->{unique}->{$name} ||= $self->_load_data($schema->model, 'unique', $name);
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

sub fetch {
    my($self, $schema, $key, $columns, %args) = @_;

    # fetch record id
    my $result_id_list = $self->get_record_id_list($schema, $key, $columns);
    return unless $result_id_list && @{ $result_id_list };

    my $results = $self->get_result_list($schema, $columns, $result_id_list);
    return unless $results && @{ $results };

    $results = [ map { $_->[1] } @{ $results } ];
}


sub lookup {
    my $self = shift;
    my $results = $self->fetch(@_);
    $results->[0];
}

sub lookup_multi {
    my($self, $schema, $ids) = @_;

    my %resultlist;
    for my $id (@{ $ids }) {
        my $key = join "\0", @{ $id };
        my $results = $self->fetch($schema, $id);
        next unless $results;        
        $resultlist{$key} = $results->[0];
    }
    \%resultlist;
}

sub get {
    my $self = shift;
    my $results = $self->fetch(@_);
    return unless $results;
    return $self->_generate_result_iterator($results), +{};
}

sub set {
    my($self, $schema, $key, $columns, %args) = @_;

    # initilaize

    # check unique
    if (@{ $schema->key } && grep { defined $_ } @{ $key }) {
        my $result_id_list = $self->get_record_id_list($schema, $key, +{});
        Carp::croak 'not unique columns' if @{ $result_id_list };
    }
    if (scalar(%{ $schema->unique })) {
        while (my($unique_name, $unique_columns) = each %{ $schema->unique }) {
            my $index = [];
            for my $column (@{ $unique_columns }) {
                push @{ $index }, $columns->{$column};
            }
            my $result_id_list = $self->get_record_id_list($schema, undef, +{ index => { $unique_name => $ index } });
            Carp::croak 'not unique columns' if @{ $result_id_list };
        }
    }

    # delete old record

    # record_id
    my $record_id = $self->generate_record_id($schema);

    # auto_increment
    if ($self->_set_auto_increment($schema, $columns, sub { $self->generate_auto_increment($schema) })) {
        # remake $key
        $key = $schema->get_key_array_by_hash($columns);
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

sub _uodate_delete_visitor {
    my($self, $schema, $key, $query, $code) = @_;

    # fetch record id
    my $result_id_list = $self->get_record_id_list($schema, $key, $query);
    return unless $result_id_list && @{ $result_id_list };

    my $results = $self->get_result_list($schema, $query, $result_id_list);
    return unless $results && @{ $results };

    # delete data
    my $data = $self->load_data($schema);
    my @rows;
    for my $id ( map { $_->[0] } @{ $results }) {
        my @ret = $code->($data, $id);
        push @rows, @ret if @ret;
    }
    return @rows ? [ @rows ] : undef;
}

sub update_direct {
    my($self, $schema, $key, $query, $columns, %args) = @_;

    $self->_uodate_delete_visitor(
        $schema, $key, $query, 
        sub {
            my($data, $id) = @_;
            $self->delete_memory_index($schema, $key, $data->{records}->{$id}, $id);
            while (my($key, $val) = each %{ $columns }) {
                $data->{records}->{$id}->{$key} = $val;
            }
            $key = $schema->get_key_array_by_hash($data->{records}->{$id});
            $self->set_memory_index($schema, $key, $data->{records}->{$id}, $id);
        }
    );
}


sub delete {
    my($self, $schema, $key, $columns, %args) = @_;

    $self->_uodate_delete_visitor(
        $schema, $key, $columns, 
        sub {
            my($data, $id) = @_;
            $self->delete_memory_index($schema, $key, $data->{records}->{$id}, $id);
            delete $data->{records}->{$id};
        }
    );
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
            $index_key = [ $index_key ] unless ref($index_key) eq 'ARRAY';
            for my $index_type (qw/ unique index /) {
                if (exists $schema->$index_type->{$index}) {
                    $result_id_list = $self->get_memory_index($schema, $index_type, $index, $index_key);
                    last;
                }
            }
        } else {
            my $data = $self->load_data($schema);
            $result_id_list = [
                sort { $a <=> $b } keys %{ $data->{records} }
            ];
        }
    }
    $result_id_list;
}

sub get_memory_index {
    my($self, $schema, $index_type, $index, $key) = @_;
    my $columns = $index_type eq 'key' ? $schema->key : $schema->$index_type->{$index};

    my $method   = "load_$index_type";
    my $key_hash = $self->$method($schema, $index);
    my $key_data = $self->_generate_key_data($key);

    my $type = scalar(@{ $key }) == scalar(@{ $columns }) ? 'key' : 'prefix';
    my $result = $key_hash->{$type}->{$key_data};
    $result ? ref($result) eq 'HASH' ? [ keys %{ $result } ] : [ $result ] : [];
}

sub set_memory_index {
    my($self, $schema, $key, $columns, $id) = @_;
    $self->_set_memory_index($schema, 'key', undef, $key, $id);

    for my $index_type (qw/ unique index /) {
        for my $index (keys %{ $schema->$index_type }) {
            my @index_key = map {
                $columns->{$_}
            } @{ $schema->$index_type->{$index} };
            $self->_set_memory_index($schema, $index_type, $index, [ @index_key ], $id);
        }
    }
}

sub _set_memory_index {
    my($self, $schema, $index_type, $index, $key, $id) = @_;
    my $columns = $index_type eq 'key' ? $schema->key : $schema->{$index_type}->{$index};

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
        for my $index (keys %{ $schema->$index_type }) {
            my @index_key = map {
                $columns->{$_}
            } @{ $schema->$index_type->{$index} };
            $self->_delete_memory_index($schema, $index_type, $index, [ @index_key ], $id);
        }
    }
}

sub _delete_memory_index {
    my($self, $schema, $index_type, $index, $key, $id) = @_;
    my $columns = $index_type eq 'key' ? $schema->key : $schema->{$index_type}->{$index};

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

## grep
sub _grep_merge_and {
    my($self, $l, $r) = @_;
    return [] unless @{ $l } && @{ $r };
    if ($l->[0]->[0] > $r->[0]->[0]) {
        my $t = $l;
        $l = $r;
        $r = $t;
    }

    my @results;
    my $ridx = 0;
    my $rmax = @{ $r };
    for my $lrow (@{ $l }) {
        my $lid = $lrow->[0];
        while ( $ridx < $rmax) {
            my $rid = $r->[$ridx]->[0];
            if ($rid == $lid) {
                push @results, $lrow;
                $ridx++;
            } elsif ($rid < $lid) {
                $ridx++;
            } else {
                last;
            }
        }
    }
    return \@results;
}
sub _grep_merge_or {
    my($self, $l, $r) = @_;
    return $l if @{ $l } && !@{ $r };
    return $r if !@{ $l } && @{ $r };
    if ($l->[0]->[0] > $r->[0]->[0]) {
        my $t = $l;
        $l = $r;
        $r = $t;
    }

    my @results;
    my $ridx = 0;
    my $rmax = @{ $r };
    for my $lrow (@{ $l }) {
        my $lid = $lrow->[0];
        while ( $ridx < $rmax) {
            my $rid = $r->[$ridx]->[0];
            if ($rid == $lid) {
                $ridx++;
                last;
            } elsif ($rid < $lid) {
                push @results, $r->[$ridx];
                $ridx++;
            } else {
                last;
            }
        }
        push @results, $lrow;
    }
    return \@results;
}

sub _grep_grep {
    my($self, $col, $val, $rows) = @_;
    my @result;
    for my $row (@{ $rows }) {
        my $ok = 0;
        unless (exists $row->[1]->{$col}) {
            next;
        }
        my $rval = $row->[1]->{$col};
        if (ref($val)) {
            if (ref($val) eq 'HASH') {
                my($op, $value) = (%{ $val });
                $op = uc($op);
                if ($op eq 'LIKE') {
                    my $is_prefix = !($value =~ s/^%//);
                    my $is_suffix = !($value =~ s/%$//);
                    my $meta_str  = join '.', map { quotemeta $_ } split '_', $value;
                    $meta_str  = '^' . $meta_str if $is_prefix;
                    $meta_str .= '$'             if $is_suffix;
                    $ok = 1 if $rval =~ /$meta_str/;

                } elsif ($op eq '=') {
                    $ok = 1 if $rval eq $value;

                } elsif ($op eq '!=') {
                    $ok = 1 unless $rval eq $value;

                } elsif ($op eq '>') {
                    $ok = 1 if $rval > $value;

                } elsif ($op eq '<') {
                    $ok = 1 if $rval < $value;

                } elsif ($op eq '>=') {
                    $ok = 1 if $rval >= $value;

                } elsif ($op eq '<=') {
                    $ok = 1 if $rval <= $value;

                } elsif (($op eq 'IN' || $op eq 'NOT IN') && ref($value) eq 'ARRAY') {
                    for my $v (@{ $value }) {
                        $ok = 1 if $rval eq $v;
                    }
                    $ok = !$ok unless $op eq 'IN';
                }
            }
        } else {
            $ok = 1 if $rval eq $val;
        }
        push @result, $row if $ok;
    }
    \@result;
}
sub _grep {
    my($self, $col, $val, $rows) = @_;
    if (lc($col) eq '-and' || lc($col) eq '-or') {
        my $results;
        my $ret;
        while (my($ccol, $cval) = splice @{ $val }, 0, 2) {
            $ret = $self->_grep( $ccol, $cval, $rows );
            if ($results) {
                $results = (lc($col) eq '-and') ? $self->_grep_merge_and($results, $ret) : $self->_grep_merge_or($results, $ret);
            } else {
                $results = $ret;
            }
        }
        $results = $ret unless $results;
        return $results;
    } else {
        ## xxx Need to support old range and transform behaviors.
        Carp::croak("Invalid/unsafe column name $col") unless $col =~ /^[\w\.]+$/ || ref($col) eq 'SCALAR';
        Carp::croak("Invalid/unsafe column value $col (unused Data::Model::SQL->_mk_term parse data)") unless !ref($val) || ref($val) eq 'HASH';
        return $self->_grep_grep($col, $val, $rows);
    }
}
sub grep {
    my($self, $schema, $query, $rows) = @_;
    return $rows unless exists $query->{where};
    my $ret = $self->_grep( -and => $query->{where}, $rows );
    return [] unless $ret;
    return $ret;
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
            int    => !!($schema->column_type($column) =~ /int/i),
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

=head1 NAME

Data::Model::Driver::Memory - storage driver for memory

=head1 SYNOPSIS

  package MyDB;
  use base 'Data::Model';
  use Data::Model::Schema;
  use Data::Model::Driver::Memory;
  
  my $dbi_connect_options = {};
  my $driver = Data::Model::Driver::Memory->new;
  
  base_driver $driver;
  install_model model_name => schema {
    ....
  };

=head1 SEE ALSO

L<Data::Model>

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo <at> shibuya <döt> plE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
