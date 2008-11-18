use t::Utils;
use Mock::Tests::Basic;
use Data::Model::Driver::DBI;
use Test::More tests => 14;

BEGIN {
    my $dbfile = temp_filename;
    our $DRIVER = Data::Model::Driver::DBI->new(
        dsn => 'dbi:SQLite:dbname=' . $dbfile,
        username => 'username',
        password => 'password',
    );
    use_ok('Mock::Basic');
    use_ok('Mock::Index');
    use_ok('Mock::ColumnSuger');
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


$mock = Mock::ColumnSuger->new;

my @author = $mock->get_schema('author')->sql->as_sql;
is($author[0], "CREATE TABLE author (
    id              INTEGER         NOT NULL PRIMARY KEY,
    name            VARCHAR(128)    NOT NULL
)");

my @book = $mock->get_schema('book')->sql->as_sql;
is($book[0], "CREATE TABLE book (
    id              INTEGER         NOT NULL PRIMARY KEY,
    author_id       INT             UNSIGNED NOT NULL,
    sub_author_id   INT             UNSIGNED NOT NULL,
    title           VARCHAR(255)    NOT NULL,
    description     TEXT            NOT NULL DEFAULT 'not yet writing',
    recommend       TEXT           
)");
is($book[1], "CREATE INDEX author_id ON book (author_id)");
