package Data::Model::Driver::DBI::DBD::SQLite;
use strict;
use warnings;
use base 'Data::Model::Driver::DBI::DBD';

sub fetch_last_id { $_[3]->func('last_insert_rowid') }

sub bind_param_attributes {
    my($self, $data_type) = @_;
    if ($data_type) { 
        if ($data_type eq 'blob') {
            return DBI::SQL_BLOB;
        } elsif ($data_type eq 'binchar') {
            return DBI::SQL_BINARY;
        }
    }
    return;
}

1;
