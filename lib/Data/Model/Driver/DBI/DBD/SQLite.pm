package Data::Model::Driver::DBI::DBD::SQLite;
use strict;
use warnings;
use base 'Data::Model::Driver::DBI::DBD';

sub fetch_last_id { $_[3]->func('last_insert_rowid') }

sub bind_param_attributes {
    my($self, $data_type) = @_;
    if ($data_type) { 
        if ($data_type =~ /blob/i || $data_type =~ /bin/i) {
            return DBI::SQL_BLOB;
        } elsif ($data_type eq 'binchar' || $data_type eq 'binary') {
            return DBI::SQL_BINARY;
        }
    }
    return;
}



sub _as_sql_column {
    my($self, $c, $column, $args) = @_;
    if (exists $args->{options}->{auto_increment} && $args->{options}->{auto_increment}) {
        $c->{_sqlite_output_primary_key} = 1;
        return sprintf('%-15s %-15s', $column, 'INTEGER') . ' NOT NULL PRIMARY KEY';
    }
    return;
}

sub _as_sql_column_type {
    my($self, $c, $column, $args) = @_;
    my $type = uc($args->{type});
    if ($type =~ /BIN/) {
        $args->{options}->{binary} = 0;
        return "BLOB";
    }
    return;
}

sub _as_sql_unsigned { '' }

sub _as_sql_primary_key {
    my($self, $c) = @_;
    return '' if $c->{_sqlite_output_primary_key};
    return;
}

sub _as_sql_unique {
    my($self, $c, $unique) = @_;
    return () unless @{ $unique };

    my @sql = ();
    for my $data (@{ $unique }) {
        my($name, $columns)  = @{ $data };
        push(@sql, 'UNIQUE (' . join(', ', @{ $columns }) . ')');
    }
    return @sql;
}

sub _as_sql_get_table_attributes {
    my($self, $c, $attributes) = @_;
    return '' unless $attributes->{SQLite};
    return $attributes->{SQLite};
}

1;
