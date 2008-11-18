use t::Utils;
use Mock::Tests::Basic;
use Data::Model::Driver::DBI;
use Test::More tests => 8;

BEGIN {
    my $dbfile = temp_filename;
    our $DRIVER = Data::Model::Driver::DBI->new(
        dsn => 'dbi:SQLite:dbname=' . $dbfile,
        username => 'username',
        password => 'password',
    );
    eval "use Mock::Basic"; $@ and die $@;
    eval "use Mock::Index"; $@ and die $@;
}


my $mock = Mock::Basic->new;

my @user = $mock->get_schema('user')->sql->as_sql;
is($user[0], "CREATE TABLE user (
    id              CHAR(255)      ,
    name            CHAR(255)      ,
    PRIMARY KEY (id)
)");

my @bookmark = $mock->get_schema('bookmark')->sql->as_sql;
is($bookmark[0], "CREATE TABLE bookmark (
    id              INTEGER         NOT NULL PRIMARY KEY,
    url             CHAR(255)      ,
    UNIQUE (url)
)");

my @bookmark_user = $mock->get_schema('bookmark_user')->sql->as_sql;
is($bookmark_user[0], "CREATE TABLE bookmark_user (
    bookmark_id     CHAR(255)      ,
    user_id         CHAR(255)      ,
    PRIMARY KEY (bookmark_id, user_id)
)");
is($bookmark_user[1], "CREATE INDEX user_id ON bookmark_user (user_id)");



$mock = Mock::Index->new;

my @multi_keys = $mock->get_schema('multi_keys')->sql->as_sql;
is($multi_keys[0], "CREATE TABLE multi_keys (
    key1            CHAR(255)      ,
    key2            CHAR(255)      ,
    key3            CHAR(255)      ,
    PRIMARY KEY (key1, key2, key3)
)");

my @multi_unique = $mock->get_schema('multi_unique')->sql->as_sql;
is($multi_unique[0], "CREATE TABLE multi_unique (
    key             INTEGER         NOT NULL PRIMARY KEY,
    unq1            CHAR(255)      ,
    unq2            CHAR(255)      ,
    unq3            CHAR(255)      ,
    UNIQUE (unq1, unq2, unq3)
)");

my @multi_index = $mock->get_schema('multi_index')->sql->as_sql;
is($multi_index[0], "CREATE TABLE multi_index (
    key             INTEGER         NOT NULL PRIMARY KEY,
    idx1            CHAR(255)      ,
    idx2            CHAR(255)      ,
    idx3            CHAR(255)      
)");
is($multi_index[1], "CREATE INDEX idx ON multi_index (idx1,idx2,idx3)");