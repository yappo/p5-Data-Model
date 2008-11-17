use t::Utils;
use Mock::Tests::Basic;
use Data::Model::Driver::DBI;

BEGIN {
    my $dbfile = temp_filename;
    our $DRIVER = Data::Model::Driver::DBI->new(
        dsn => 'dbi:SQLite:dbname=' . $dbfile,
        username => 'username',
        password => 'password',
    );
    eval "use Mock::Basic"; $@ and die $@;
    setup_sqlite( 'dbi:SQLite:dbname=' . $dbfile => Mock::Basic->as_sqls );
}

my $mock = Mock::Basic->new;
Mock::Tests::Basic->set_mock($mock);
Mock::Tests::Basic->runtests;
