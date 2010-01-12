package Data::Model;

use strict;
use warnings;
our $VERSION = '0.00005';

use Carp ();
$Carp::Internal{(__PACKAGE__)}++;

use Data::Model::Iterator;
use Data::Model::Transaction;

our $RUN_VALIDATION;
if (exists $ENV{DATA_MODE_RUN_VALIDATION}) {
    $RUN_VALIDATION = $ENV{DATA_MODE_RUN_VALIDATION} ? 1 : 0;
} else {
    $RUN_VALIDATION = 1; # default is any time validation
    # $RUN_VALIDATION = $ENV{HARNESS_ACTIVE} ? 1 : 0;
}
use Params::Validate ':all';


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
    (ref($self) || $self) . '::' . $model;
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


    # for query param validation
    if ($RUN_VALIDATION && $query) {
        my @p = %{ $query };
        validate(
            @p, {
                index => {
                    type     => HASHREF | UNDEF,
                    optional => 1,
                    callbacks => {
                        has_index_name => sub {
                            return 1 unless $_[0];
                            return 0 unless scalar(@{ [ %{ $_[0] } ] }) == 2;
                            my($name) = %{ $_[0] };
                            $schema->has_index($name);
                        },
                    },
                },
                where => {
                    type     => HASHREF | ARRAYREF | UNDEF,
                    optional => 1,
                },
                order => {
                    type     => HASHREF | ARRAYREF | UNDEF,
                    optional => 1,
                },
                group => {
                    type     => HASHREF | ARRAYREF | UNDEF,
                    optional => 1,
                },
                limit => {
                    type     => SCALAR | UNDEF,
                    optional => 1,
                },
                offset => {
                    type     => SCALAR | UNDEF,
                    optional => 1,
                },
            },
        );
    }


    # if first key is undef then nothing keys
    $key_array = [] if $key_array && ref($key_array) && !defined $key_array->[0];

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

    return [] if ($key_array && !@{ $key_array });
    return [] unless $key_array || $query;
    return [ $key_array, $query, @_ ];
}

sub lookup {
    my($self, $model, $id) = @_;
    Carp::croak "The 'lookup' method can not be performed during a transaction." if $self->{active_transaction};
    my $schema = $self->get_schema($model);
    return unless $schema;

    $id = [ $id ] unless ref($id) eq 'ARRAY';

    # deflating
    my $id_hash = $schema->get_columns_hash_by_key_array_and_hash(+{}, $id);
    $schema->deflate($id_hash);
    $id = $schema->get_key_array_by_hash( $id_hash );

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
    Carp::croak "The 'lookup_multi' method can not be performed during a transaction." if $self->{active_transaction};
    my $schema = $self->get_schema($model);
    return unless $schema;

    $ids = [ $ids ] unless ref($ids) eq 'ARRAY';
    my $id_size = scalar(@{ $schema->key });
    my @id_list;
    for my $id (@{ $ids }) {
        $id = [ $id ] unless ref($id) eq 'ARRAY';

        Carp::confess 'The number of key is wrong'
                unless scalar(@{ $id }) == $id_size;

        # deflating
        my $id_hash = $schema->get_columns_hash_by_key_array_and_hash(+{}, $id);
        $schema->deflate($id_hash);
        $id = $schema->get_key_array_by_hash( $id_hash );

        push @id_list, $id;
    }

    my $results = $schema->{driver}->lookup_multi( $schema, \@id_list );
    return (undef) x scalar(@id_list) unless $results && ref($results) eq 'HASH';

    while (my($id, $data) = each %{ $results }) {
        my $obj = $data;
        unless ($schema->{options}->{bare_row} || !$obj) {
            $obj = $schema->new_obj($self, $data);
            $schema->inflate($obj);
            $schema->call_trigger('post_load', $obj);
        }
        $results->{$id} = $obj;
    }

    map { $results->{join("\0", @{ $_ })} } @id_list;
}


#  $model->get( model_name => 'key' );
#  $model->get( model_name => [qw/ key1 key2 /] );
#  $model->get( model_name => 'key' => { query options ... });
#  $model->set( model_name => { search query, ... } );
sub get {
    my $self   = shift;
    Carp::croak "The 'get' method can not be performed during a transaction." if $self->{active_transaction};
    my $model  = shift;
    my $schema = $self->get_schema($model);
    return unless $schema;

    my $query = $self->_get_query_args($schema, @_);
    return if @_ && !@{ $query }; # undef key
    local $schema->{schema_obj} = $self;
    my($iterator, $iterator_options) = $schema->{driver}->get( $schema, @{ $query } );
    unless ($iterator) {
        return if wantarray;
        return Data::Model::Iterator::Empty->new;
    }

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
    my $self = shift;
    Carp::croak "The 'get_multi' method can not be performed during a transaction." if $self->{active_transaction};
}


#  $model->set( model_name => 'key' );
#  $model->set( model_name => [qw/ key1 key2 /] );
#  $model->set( model_name => 'key' => { column => 'value', ... });
#  $model->set( model_name => [qw/ key1 key2 /] => { column => 'value', ... } );
#  $model->set( model_name => { column => 'value', ... } );
sub set {
    Carp::croak "The 'set' method can not be performed during a transaction." if $_[0]->{active_transaction};
    shift->_insert_or_replace(0, @_);
}

sub replace {
    Carp::croak "The 'replace' method can not be performed during a transaction." if $_[0]->{active_transaction};
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
    my $self = shift;
    Carp::croak "The 'set_multi' method can not be performed during a transaction." if $self->{active_transaction};
}


sub _get_schema_by_row {
    my($self, $row) = @_;

    my $class = ref($row);
    return unless $class;

    my($klass, $model) = $class =~ /^(.+)::([^:]+)$/;
    return unless (ref($self) || $self) eq $klass;
    return $self->get_schema($model);
}

sub update {
    my $self = shift;
    Carp::croak "The 'update' method can not be performed during a transaction." if $self->{active_transaction};
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


#  $model->update_direct( model_name => 'key', +{ querys }, +{ update columns } );
#  $model->update_direct( model_name => [qw/ key1 key2 /], +{ querys }, +{ update columns } );
#  $model->update_direct( model_name => +{ querys }, +{ update columns } );
# direct_update get しないで直接 updateする where の組み立ては get/delete と同じ
sub update_direct {
    my $self   = shift;
    Carp::croak "The 'update_direct' method can not be performed during a transaction." if $self->{active_transaction};
    my $model  = shift;

    my $schema = $self->get_schema($model);
    return unless $schema;

    my $query = $self->_get_query_args($schema, @_);
    return unless @{ $query };

    $schema->deflate($query->[2]);
    $schema->call_trigger('pre_save', $query->[2]);
    $schema->call_trigger('pre_update', $query->[2]);

    local $schema->{schema_obj} = $self;
    $schema->{driver}->update_direct( $schema, @{ $query } );
}


#  $model->delete( model_name => 'key' );
#  $model->delete( model_name => [qw/ key1 key2 /] );
sub delete {
    my $self = shift;
    Carp::croak "The 'delete' method can not be performed during a transaction." if $self->{active_transaction};
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
    Carp::croak "The 'delete_direct' method can not be performed during a transaction." if $self->{active_transaction};
    my $model  = shift;
    my $schema = $self->get_schema($model);
    return unless $schema;

    my $query = $self->_get_query_args($schema, @_);
    return unless @{ $query };

    local $schema->{schema_obj} = $self;
    $schema->{driver}->delete( $schema, @{ $query } );
}

sub delete_multi {
    my $self   = shift;
    Carp::croak "The 'delete_multi' method can not be performed during a transaction." if $self->{active_transaction};
}


# for transactions
sub txn_scope {
    Carp::croak "The 'txn_scope' method can not be performed during a transaction." if $_[0]->{active_transaction};
    Data::Model::Transaction->new( @_ );
}

sub txn_begin {
    my $self = shift;
    Carp::croak "The 'txn_begin' method can not be performed during a transaction." if $self->{active_transaction};
    my $driver = $self->get_base_driver;
    Carp::croak 'You cannot use transaction, Because base_driver is not set by schema.' unless $driver;
    $self->{active_transaction} = 1;

    $driver->txn_begin;
}

sub txn_rollback {
    my $self = shift;
    my $driver = $self->get_base_driver;

    $driver->txn_rollback;
    $self->txn_end;
    1;
}

sub txn_commit {
    my $self = shift;
    my $driver = $self->get_base_driver;

    $driver->txn_commit;
    $self->txn_end;
    1;
}

sub txn_end {
    my $self = shift;
    my $driver = $self->get_base_driver;
    $self->{active_transaction} = 0;
    $driver->txn_end;
}


1;
__END__

=head1 NAME

Data::Model - model interface which had more data sources unified, a.k.a data/object mapper

=head1 SYNOPSIS

  package Your::Model;
  use base 'Data::Model';
  use Data::Model::Schema;
  use Data::Model::Driver::DBI;
  
  my $dbfile = '/foo/bar.db';
  my $driver = Data::Model::Driver::DBI->new(
      dsn => "dbi:SQLite:dbname=$dbfile",
  );
  base_driver( $driver );
  
  install_model user => schema {
      key 'id';
      columns qw/
          id
          name
      /;
  };
  
  # create database file
  unless (-f $dbfile) {
      my $dbh = DBI->connect($dsn, '', '', { RaiseError => 1, PrintError => 0 });
      for my $sql (__PACKAGE__->as_sqls) {
          $dbh->do( $sql );
      }
      $dbh->disconnect;
  }
  
  # in your script:
  use Your::Model;
  
  my $model = Your::Model->new;
  
  # insert
  my $row = $model->set(
      user => {
          id => 1,
      }
  );
  
  my $row = $model->lookup( user => 1 );
  $row->delete;

=head1 DESCRIPTION

Data::Model is can use as ORM which can be defined briefly.

There are few documents. It is due to be increased in the near future.

=head1 SCHEMA DEFINITION

One package can define two or more tables using DSL.

see L<Data::Model::Schema>.

=head1 METHODS

=head2 new([ \%options ]);

  my $model = Class->new;

=head2 lookup($target => $key)

  my $row = $model->lookup( user => $id );
  print $row->name;

=head2 lookup_multi($target => \@keylist)

  my @row = $model->lookup_multi( user => [ $id1, $id2 ] );
  print $row[0]->name;
  print $row[1]->name;

=head2 get($target => $key [, \%options ])

  my $iterator = $model->get( user => { 
      id => {
          IN => [ $id1, $id2 ],
      }
  });
  while (my $row = $iterator->next) {
      print $row->name;
  }
  # or
  while (my $row = <$iterator>) {
      print $row->name;
  }
  # or
  while (<$iterator>) {
      print $_->name;
  }

=head2 set($target => $key, => \%values [, \%options ])

  $model->set( user => {
    id   => 3,
    name => 'insert record',
  });

=head2 delete($target => $key [, \%options ])

  $model->delete( user => 3 ); # id = 3 is deleted

=head1 ROW OBJECT METHODS

row object is provided by L<Data::Model::Row>.

=head2 update

  my $row = $model->lookup( user => $id );
  $row->name('update record');
  $row->update;

=head2 delete

  my $row = $model->lookup( user => $id );
  $row->delete;

=head1 TRANSACTION

see L<Data::Model::Transaction>.

=head1 DATA DRIVERS

=head2 DBI

see L<Data::Model::Driver::DBI>.

=head2 DBI::MasterSlave

master-slave composition for mysql.

see L<Data::Model::Driver::DBI::MasterSlave>.

=head2 Cache

Cash of the result of a query.

see L<Data::Model::Driver::Cache::HASH>,
see L<Data::Model::Driver::Cache::Memcached>.

=head2 Memcached

memcached is used for data storage.

see L<Data::Model::Driver::Memcached>.

=head2 Queue::Q4M

queuing manager for Q4M.

see L<Data::Model::Driver::Queue::Q4M>.

=head2 Memory

on memory storage.

see L<Data::Model::Driver::Memory>.

=head1 SEE ALSO

L<Data::Model::Row>,
L<Data::Model::Iterator>

=head1 ACKNOWLEDGEMENTS

Benjamin Trott more idea given by L<Data::ObjectDriver>

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo <at> shibuya <döt> plE<gt>

=head1 REPOSITORY

  git clone git://github.com/yappo/p5-Data-Model.git

Data::Model's Git repository is hosted at L<http://github.com/yappo/p5-Data-Model>.
patches and collaborators are welcome.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
