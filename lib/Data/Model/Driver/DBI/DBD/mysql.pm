package Data::Model::Driver::DBI::DBD::mysql;
use strict;
use warnings;
use base 'Data::Model::Driver::DBI::DBD';

sub fetch_last_id { $_[3]->{mysql_insertid} || $_[3]->{insertid} }

1;

