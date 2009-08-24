package Data::Model::Driver::DBI::DBD::mysql;
use strict;
use warnings;
use base 'Data::Model::Driver::DBI::DBD';

sub fetch_last_id { $_[3]->{mysql_insertid} || $_[3]->{insertid} }

sub _as_sql_inner_index {
    my($self, $c, $index) = @_;
    return () unless @{ $index };

    my @sql = ();
    for my $data (@{ $index }) {
        my($name, $columns)  = @{ $data };
        push(@sql, "INDEX $name (" . join(', ', @{ $columns }) . ')');
    }
    return @sql;
}

sub has_support {
    exists {
        on_duplicate_key_update => 1,
    }->{$_[1]};
}

sub _as_sql_index { '' }

sub _as_sql_column_type {
    my($self, $c, $column, $args) = @_;
    my $type = uc($args->{type});
    if ($type eq 'BINARY' || $type eq 'VARBINARY') {
        $args->{options}->{binary} = 0;
        my $size = $args->{options}->{size} || 0;
        $size = 0 unless $size =~ /^\d+$/;
        return "$type($size)";
    }
    return;
}

sub _as_sql_get_table_attributes {
    my($self, $c, $attributes) = @_;
    return '' unless $attributes->{mysql};
    return $attributes->{mysql};
}

1;

