package Data::Model::Driver;
use strict;
use warnings;

use Carp ();

sub new { 
    my($class, %args) = @_;
    my $self = bless { %args }, shift;
    $self->init;
    $self;
}

sub init {}
sub attach_model {}
sub detach_model {}

sub cache_key_prefix { shift->{cache_key_prefix} }

sub cache_key {
    my($self, $schema, $id) = @_;

    Carp::confess 'The number of key is wrong'
            unless scalar(@{ $id }) == scalar(@{ $schema->key });

    join ':', ($self->cache_key_prefix ? $self->cache_key_prefix : ()), $schema->model, ref($id) eq 'ARRAY' ? @$id : $id;
}


my $KEYSEPARATE = "\0";
sub _generate_key_data {
    my($self, $key_array) = @_;
    join $KEYSEPARATE, @{ $key_array };
}

sub _generate_result_iterator {
    my($self, $results) = @_;

    my $count = 0;
    my $max = scalar @{ $results };
    sub {
        my $reset = shift;
        $count = 0 if $reset;
        return unless $count < $max;
        $results->[$count++];
    };
}

sub _set_auto_increment {
    my($self, $schema, $columns, $code) = @_;
    my $count = 0;
    if (my @keys = @{ $schema->key }) {
        for my $column (@keys) {
            if (exists $schema->column_options($column)->{auto_increment} && 
                    $schema->column_options($column)->{auto_increment}) {
                $columns->{$column} = $code->();
                $count++;
            }
        }
    }
    $count;
}

sub _as_sql_hook {}

sub lookup {}
sub lookup_multi {}
sub get {}
sub set {}
sub delete {}
sub update {}
sub replace {}

sub get_multi {}
sub set_multi {}
sub delete_multi {}

sub txn_begin { Carp::croak 'not transaction support' }
sub txn_rollback { Carp::croak 'not transaction support' }
sub txn_commit { Carp::croak 'not transaction support' }
sub txn_end {}

1;
