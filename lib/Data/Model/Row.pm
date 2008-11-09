package Data::Model::Row;
use strict;
use warnings;

use Class::Trigger qw( pre_save post_save post_load );

sub new {
    my($class, $columns) = @_;
    bless {
        column_values => { %{ $columns } },
        changed_cols  => +{},
    }, $class;
}

1;
