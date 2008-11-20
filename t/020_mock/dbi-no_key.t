use t::Utils;
use Mock::Tests::NoKey;
use Data::Model::Driver::DBI;

BEGIN {
    my $dbfile = temp_filename;
    our $DRIVER = Data::Model::Driver::DBI->new(
        dsn => 'dbi:SQLite:dbname=' . $dbfile,
        username => 'username',
        password => 'password',
    );
    eval "use Mock::NoKey"; $@ and die $@;
    setup_sqlite( 'dbi:SQLite:dbname=' . $dbfile => Mock::NoKey->as_sqls );
}

my $mock = Mock::NoKey->new;
Mock::Tests::NoKey->set_mock($mock);
Mock::Tests::NoKey->runtests;
