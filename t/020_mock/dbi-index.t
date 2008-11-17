use t::Utils;
use Mock::Tests::Index;
use Data::Model::Driver::DBI;

BEGIN {
    my $dbfile = temp_filename;
    our $DRIVER = Data::Model::Driver::DBI->new(
        dsn => 'dbi:SQLite:dbname=' . $dbfile,
        username => 'username',
        password => 'password',
    );
    eval "use Mock::Index"; $@ and die $@;
    setup_sqlite( Mock::Index->as_sqls, $dbfile );
}

my $mock = Mock::Index->new;
Mock::Tests::Index->set_mock($mock);
Mock::Tests::Index->runtests;
