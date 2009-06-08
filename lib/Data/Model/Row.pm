package Data::Model::Row;
use strict;
use warnings;

use Carp ();
$Carp::Internal{(__PACKAGE__)}++;

sub new {
    my($class, $model, $columns) = @_;
    $columns ||= {};
    bless {
        model         => $model,
        column_values => { %{ $columns } },
        alias_values  => +{},
        changed_cols  => +{},
        original_cols => +{},
    }, $class;
}

sub update {
    my $self = shift;
    $self->{model}->update($self, @_);
}

sub delete {
    my $self = shift;
    $self->{model}->delete($self, @_);
}

sub get_column {
    my($self, $name) = @_;
    $self->{column_values}->{$name};
}
sub get_columns {
    my $self = shift;
    my $schema = $self->{model}->_get_schema_by_row($self);
    my $columns = +{};
    for my $name (keys %{ $schema->{column} }) {
        $columns->{$name} = $self->{column_values}->{$name};
    }
    $columns;
}

sub get_original_column {
    my($self, $name) = @_;
    $self->{original_cols}->{$name} || $self->{column_values}->{$name};
}

sub get_changed_columns {
    my $self = shift;
    +{ %{ $self->{changed_cols} } };
}

1;
