package Data::Model;

use strict;
use warnings;
our $VERSION = '0.01';

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
    if (ref($class) && @_ == 1){ 
        
    }
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
    $self->__properties->{schema}->{$model};    
}

sub get_driver {
    my($self, $model) = @_;
    $self->get_schema($model)->{driver};
}

sub get_key_array_by_hash {
    my($self, $schema, $hash) = @_;
}

sub get_columns_hash_by_key_array_and_hash {
    my($self, $schema, $hash, $array) = @_;
    my $ret = {};

    # by column
    for my $column (keys %{ $schema->{column} }) {
        $ret->{$column} = $hash->{$column};
    }

    # by key
    my $key = $schema->{key};
    $key = [ $key ] unless ref($key) eq 'ARRAY';
    @{ $ret }{@{ $key }} = @{ $array };

    $ret;
}


## get / set / delete

sub _get_query_args {
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

    return [ $key_array, $query, @_ ];
}

=head2 delete

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

    my $query = _get_query_args($schema, @_);
    local $schema->{schema_obj} = $self;
    my($iterator, $iterator_options) = $schema->{driver}->get( $schema, @{ $query } );
    return unless $iterator;

    if (wantarray) {
        my @objs = ();
        while (my $data = $iterator->()) {
            my $obj;
            unless ($schema->{options}->{bare_row}) {
                $obj = $schema->{class}->new($data);
                $obj->call_trigger('post_load'); # inflate
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
            my $obj = $schema->{class}->new(shift);
            $obj->call_trigger('post_load'); # inflate 
            $obj;
        },
    );
}

sub get_multi {
}

=head2 delete

  $model->set( model_name => 'key' );
  $model->set( model_name => [qw/ key1 key2 /] );
  $model->set( model_name => 'key' => { column => 'value', ... });
  $model->set( model_name => [qw/ key1 key2 /] => { column => 'value', ... } );
  $model->set( model_name => { column => 'value', ... } );

=cut

sub set {
    my $self   = shift;
    my $model  = shift;
    return $self->update($model, @_) if ref($model) && $model->isa('Data::Model::Row');
    my $schema = $self->get_schema($model);
    return unless $schema;
    return unless exists $_[0];

    # get key array
    my $key_array;
    my $columns;
    if (ref($_[0]) eq 'HASH') {
        ## ->set( modelname => { key => value, ... } );
        $columns = shift;
        $key_array = $self->get_key_array_by_hash($schema, $columns);
    } elsif (ref($_[0]) eq 'ARRAY') {
        ## ->set( modelname => [ keys ] => { key => value, ... } );
        $key_array = shift;
    } elsif (!ref($_[0])) {
        ## ->set( modelname => 'key' => { key => value, ... } );
        $key_array = [ shift ];
    } else {
        return;
    }

    # get columns
    if ($columns) {
        ## nop
    } elsif (ref($_[0]) eq 'HASH') {
        ## get hash columns data
        my $hash = shift;
        $columns = $self->get_columns_hash_by_key_array_and_hash($schema, $hash, $key_array);
    } else {
        $columns = $self->get_columns_hash_by_key_array_and_hash($schema, {}, $key_array);
    }

    # $columns deflate

    local $schema->{schema_obj} = $self;
    my $result = $schema->{driver}->set( $schema, $key_array => $columns, @_ );
    return unless $result;

    unless ($schema->{options}->{bare_row}) {
        my $obj = $schema->{class}->new($result);
        $obj->call_trigger('post_load'); # inflate
        return $obj;
    }
    return $result;
}

sub set_multi {
}


sub update {
    my($self, $row, %args) = @_;
    my $class = ref($row);
    return unless $class;
    my($klass, $model) = $class =~ /^(.+)::([^:]+)$/;
    return unless ref($self) eq $klass;
    my $schema = $self->get_schema($model);
    return unless $schema;
    return unless @{ $schema->{key} } > 0;

    my $columns = +{};
    for my $name (keys %{ $schema->{column} }) {
        $columns->{$name} = $row->$name;
    }
    my $key_array = $self->get_key_array_by_hash($schema, $columns);

    # update された column のみ $columns に入れる
    # $columns deflate

    my $result = $schema->{driver}->update( $schema, $key_array, $columns, %args);
    return unless $result;

    $row;
}


=head2 delete

  $model->delete( model_name => 'key' );
  $model->delete( model_name => [qw/ key1 key2 /] );

=cut

sub delete {
    my $self   = shift;
    my $model  = shift;
    my $schema = $self->get_schema($model);
    return unless $schema;

    my $query = _get_query_args($schema, @_);
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
