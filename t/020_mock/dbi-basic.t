use t::Utils;
use Mock::Tests::Basic;

our $DBFILE = temp_filename;
eval "use Mock::DBI::Basic"; $@ and die $@;
setup_sqlite( Mock::DBI::Basic->as_sqls, $DBFILE );

my $mock = Mock::DBI::Basic->new;
Mock::Tests::Basic->set_mock($mock);
Mock::Tests::Basic->runtests;
