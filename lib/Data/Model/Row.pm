package Data::Model::Row;
use strict;
use warnings;

use Class::Trigger qw( pre_save post_save post_load );

sub new {
    my($class, $model, $columns) = @_;
    $columns ||= {};
    bless {
        model         => $model,
        column_values => { %{ $columns } },
        changed_cols  => +{},
    }, $class;
}

sub update {
    my $self = shift;
    $self->{model}->update($self, @_);
}

1;
