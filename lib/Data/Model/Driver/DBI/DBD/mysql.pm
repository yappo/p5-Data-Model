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

sub _as_sql_index { '' }

sub _as_sql_get_table_attributes {
    my($self, $c, $attributes) = @_;
    return '' unless $attributes->{mysql};
    return $attributes->{mysql};
}

1;
