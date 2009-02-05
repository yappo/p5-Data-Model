package Data::Model;

use strict;
use warnings;
our $VERSION = '0.01';

use Carp ();

use Data::Model::Iterator;

## for schema methods
sub driver  {};
sub model   {};
sub schema  {};
sub column  {};
sub columns {};
sub key     {};
sub index   {};
sub unique  {};
sub schema_options {};
sub __properties { +{} }

sub new {
    my $class = shift;
    bless {
        schema_class => $class,
    }, $class;
}

## data model attributes

sub get_schema_class {
    my($self, $model) = @_;
    ref($self) . '::' . $model;
}

sub get_schema {
    my($self, $model) = @_;
    my $schema = $self->__properties->{schema}->{$model};
    Carp::croak "not defined schema $model" unless $schema;
    $schema;
}

sub clear_all_drivers {
    my $self = shift;
    for my $model ($self->schema_names) {
        $self->set_driver($model, undef);
    }
}

sub get_base_driver {
    shift->__properties->{base_driver};
}

sub set_base_driver {
    my($self, $driver) = @_;
    $self->__properties->{base_driver} = $driver;
    for my $model ($self->schema_names) {
        $self->set_driver($model, $driver) unless $self->get_driver($model);
    }
}

sub get_driver {
    my($self, $model) = @_;
    $self->get_schema($model)->{driver};
}

sub set_driver {
    my($self, $model, $driver) = @_;
    my $schema = $self->get_schema($model);
    my $old = (exists $schema->{driver} && $schema->{driver});
    if ($old) {
        $old->detach_model($model, $schema);
    }
    $schema->driver($driver);
    if ($driver) {
        $driver->attach_model($model, $schema);
    }
}


sub schema_names {
    my $self = shift;
    keys %{ $self->__properties->{schema} };
}

sub as_sqls {
    my $self   = shift;
    my $target = shift;
    my @sql = ();
    for my $model ($self->schema_names) {
        next if $target && $model ne $target;
        push @sql, $self->get_schema($model)->sql->as_sql;
    }
    @sql;
}

## get / set / delete

sub _get_query_args {
    my $self   = shift;
    my $schema = shift;
    return [] unless exists $_[0];

    # get key array or query
    my $key_array = undef;
    my $query = undef;
    if (ref($_[0]) eq 'HASH') {
        ## ->get( modelname => { search query } );
        $query = shift;
    } elsif (ref($_[0]) eq 'ARRAY') {
        ## ->get( modelname => [ keys ]);
        $key_array = shift;
    } elsif (!ref($_[0])) {
        ## ->get( modelname => 'key');
        $key_array = [ shift ];
    } else {
        return [];
    }

    # get query
    if ($query) {
        ## nop
    } elsif (ref($_[0]) eq 'HASH') {
        ## get query
        $query = shift;
    } else {
        shift;
    }

    # deflate search key
    if ($schema->has_deflate) {
        if ($key_array) {
            my $columns = $schema->get_columns_hash_by_key_array_and_hash(+{}, $key_array);
            $schema->deflate($columns);
            $key_array = $schema->get_key_array_by_hash( $columns );
        }

        # deflate search index
        if ($query && ref($query->{index}) eq 'HASH') {
            my($name, $key_array) = ( %{ $query->{index} } );
            $key_array = [ $key_array ] unless ref($key_array) eq 'ARRAY';
            my $columns = $schema->get_columns_hash_by_key_array_and_hash(+{}, $key_array, $name);
            $schema->deflate($columns);
            $query->{index} = { $name => $schema->get_key_array_by_hash($columns, $name) };
        }
    }

    return [ $key_array, $query, @_ ];
}

sub lookup {
    my($self, $model, $id) = @_;
    my $schema = $self->get_schema($model);
    return unless $schema;

    $id = [ $id ] unless ref($id) eq 'ARRAY';

    Carp::confess 'The number of key is wrong'
            unless scalar(@{ $id }) == scalar(@{ $schema->key });

    my $data = $schema->{driver}->lookup( $schema, $id );
    return unless $data;

    my $obj = $data;
    unless ($schema->{options}->{bare_row}) {
        $obj = $schema->new_obj($self, $data);
        $schema->inflate($obj);
        $schema->call_trigger('post_load', $obj);
    }
    return $obj;
}

sub lookup_multi {
    my($self, $model, $ids) = @_;
    my $schema = $self->get_schema($model);
    return unless $schema;

    my @id_list = map {
        ref($_) eq 'ARRAY' ? $_ : [ $_ ]
    } ref($ids) eq 'ARRAY' ? @{ $ids } : ( $ids );

    my $id_size = scalar(@{ $schema->key });
    for my $id (@id_list) {
        Carp::confess 'The number of key is wrong'
                unless scalar(@{ $id }) == $id_size;
    }

    my $results = $schema->{driver}->lookup_multi( $schema, \@id_list );
    return unless $results && ref($results) eq 'HASH';

    while (my($id, $data) = each %{ $results }) {
        my $obj = $data;
        unless ($schema->{options}->{bare_row}) {
            $obj = $schema->new_obj($self, $data);
            $schema->inflate($obj);
            $schema->call_trigger('post_load', $obj);
        }
        $results->{$id} = $obj;
    }

    map { $results->{join("\0", @{ $_ })} } @id_list;
}

=head2 get

  $model->get( model_name => 'key' );
  $model->get( model_name => [qw/ key1 key2 /] );
  $model->get( model_name => 'key' => { query options ... });
  $model->set( model_name => { search query, ... } );

=cut

sub get {
    my $self   = shift;
    my $model  = shift;
    my $schema = $self->get_schema($model);
    return unless $schema;

    my $query = $self->_get_query_args($schema, @_);
    local $schema->{schema_obj} = $self;
    my($iterator, $iterator_options) = $schema->{driver}->get( $schema, @{ $query } );
    return unless $iterator;

    if (wantarray) {
        my @objs = ();
        while (my $data = $iterator->()) {
            my $obj = $data;
            unless ($schema->{options}->{bare_row}) {
                $obj = $schema->new_obj($self, $data);
                $schema->inflate($obj);
                $schema->call_trigger('post_load', $obj);
            }
            push @objs, $obj;
        }
        $iterator_options->{end}->() if exists $iterator_options->{end} && ref($iterator_options->{end}) eq 'CODE';
        return @objs;
    }
    return Data::Model::Iterator->new(
        $iterator,
        %{ $iterator_options },
        wrapper => sub {
            return shift if $schema->{options}->{bare_row};
            my $obj = $schema->new_obj($self, shift);
            $schema->inflate($obj);
            $schema->call_trigger('post_load', $obj);
            $obj;
        },
    );
}

sub get_multi {
}

=head2 set

  $model->set( model_name => 'key' );
  $model->set( model_name => [qw/ key1 key2 /] );
  $model->set( model_name => 'key' => { column => 'value', ... });
  $model->set( model_name => [qw/ key1 key2 /] => { column => 'value', ... } );
  $model->set( model_name => { column => 'value', ... } );

=cut

sub set {
    shift->_insert_or_replace(0, @_);
}

sub replace {
    shift->_insert_or_replace(1, @_);
}

sub _insert_or_replace {
    my $self       = shift;
    my $is_replace = shift;
    my $model      = shift;
    return $self->update($model, @_) if ref($model) && $model->isa('Data::Model::Row');
    my $schema = $self->get_schema($model);
    return unless $schema;
    # return unless exists $_[0];

    # get key array
    my $key_array;
    my $columns;
    if (ref($_[0]) eq 'HASH') {
        ## ->set( modelname => { key => value, ... } );
        $columns = shift;
        $key_array = $schema->get_key_array_by_hash($columns);
    } elsif (ref($_[0]) eq 'ARRAY') {
        ## ->set( modelname => [ keys ] => { key => value, ... } );
        $key_array = shift;
    } elsif (!ref($_[0])) {
        ## ->set( modelname => 'key' => { key => value, ... } );
        $key_array = [ shift ];
    } else {
        # return;
    }

    # get columns
    if ($columns) {
        ## nop
    } elsif (ref($_[0]) eq 'HASH') {
        ## get hash columns data
        my $hash = shift;
        $columns = $schema->get_columns_hash_by_key_array_and_hash($hash, $key_array);
    } else {
        $columns = $schema->get_columns_hash_by_key_array_and_hash(+{}, $key_array);
    }

    # deflate
    $schema->deflate($columns);
    $key_array = $schema->get_key_array_by_hash( $columns );

    # triggers
    $schema->call_trigger('pre_save', $columns);
    $schema->set_default($columns); # set default
    $schema->call_trigger('pre_insert', $columns);

    local $schema->{schema_obj} = $self;
    my $method = $is_replace ? 'replace' : 'set';
    my $result = $schema->{driver}->$method( $schema, $key_array => $columns, @_ );
    return unless $result;

    unless ($schema->{options}->{bare_row}) {
        my $obj = $schema->new_obj($self, $result);
        $schema->inflate($obj);
        $schema->call_trigger('post_load', $obj);
        return $obj;
    }
    return $result;
}

sub set_multi {
}


sub _get_schema_by_row {
    my($self, $row) = @_;

    my $class = ref($row);
    return unless $class;

    my($klass, $model) = $class =~ /^(.+)::([^:]+)$/;
    return unless ref($self) eq $klass;
    return $self->get_schema($model);
}

sub update {
    my $self = shift;
    my $row  = shift;
    return $self->update_direct($row, @_) unless ref($row) && $row->isa('Data::Model::Row');

    my $schema = $self->_get_schema_by_row($row);
    return unless $schema;
    return unless @{ $schema->{key} } > 0; # not has key

    return unless scalar(%{ $row->get_changed_columns });

    my $columns         = $row->get_columns;
    my $changed_columns = $row->get_changed_columns;
    my $old_columns     = +{ %{ $columns }, %{ $changed_columns } };

    if ($schema->has_deflate) {
        # deflate
        $schema->deflate($columns);
        $schema->deflate($old_columns);
    }

    $schema->call_trigger('pre_save', $columns);
    $schema->call_trigger('pre_update', $columns, $old_columns);

    my $key_array     = $schema->get_key_array_by_hash($columns);
    my $old_key_array = $schema->get_key_array_by_hash($old_columns);

    my $result = $schema->{driver}->update(
        $schema, $old_key_array, $key_array, $old_columns, $columns, $changed_columns, @_
    );
    $row->{changed_cols} = +{};
    return unless $result;

    $row;
}

=head2 update_direct

  $model->update_direct( model_name => 'key', +{ querys }, +{ update columns } );
  $model->update_direct( model_name => [qw/ key1 key2 /], +{ querys }, +{ update columns } );
  $model->update_direct( model_name => +{ querys }, +{ update columns } );

=cut

#direct_update get しないで直接 updateする where の組み立ては get/delete と同じ
sub update_direct {
    my $self   = shift;
    my $model  = shift;

    my $schema = $self->get_schema($model);
    return unless $schema;

    my $query = $self->_get_query_args($schema, @_);
    return unless $query;

    $schema->deflate($query->[2]);
    $schema->call_trigger('pre_save', $query->[2]);
    $schema->call_trigger('pre_update', $query->[2]);

    local $schema->{schema_obj} = $self;
    $schema->{driver}->update_direct( $schema, @{ $query } );
}

=head2 delete

  $model->delete( model_name => 'key' );
  $model->delete( model_name => [qw/ key1 key2 /] );

=cut

sub delete {
    my $self = shift;
    my $row  = shift;
    return $self->delete_direct($row, @_) unless ref($row) && $row->isa('Data::Model::Row');

    my $schema = $self->_get_schema_by_row($row);
    return unless $schema;
    return unless @{ $schema->{key} } > 0; # not has key

    my $columns       = $row->get_columns;
    my $key_array     = $schema->get_key_array_by_hash($columns);

    local $schema->{schema_obj} = $self;
    $schema->{driver}->delete( $schema, $key_array, @_ );
}

sub delete_direct {
    my $self   = shift;
    my $model  = shift;
    my $schema = $self->get_schema($model);
    return unless $schema;

    my $query = $self->_get_query_args($schema, @_);
    return unless $query;

    local $schema->{schema_obj} = $self;
    $schema->{driver}->delete( $schema, @{ $query } );
}

sub delete_multi {
}


1;
__END__

=head1 NAME

Data::Model - 

=head1 SYNOPSIS

  use Data::Model;

=head1 DESCRIPTION

Data::Model is

=head1 METHODS

=head2 new([ \%options ]);

=head2 get($target => $key [, \%options ])

=head2 set($target => $key, => \%values [, \%options ])

=head2 delete($target => $key [, \%options ])

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo <at> shibuya <döt> plE<gt>

=head1 SEE ALSO

=head1 REPOSITORY

  svn co http://svn.coderepos.org/share/lang/perl/Data-Model/trunk Data-Model

Data::Model is Subversion repository is hosted at L<http://coderepos.org/share/>.
patches and collaborators are welcome.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
