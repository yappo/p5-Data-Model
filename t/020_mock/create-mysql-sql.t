use t::Utils;
use Mock::Tests::Basic;
use Data::Model::Driver::DBI;
use Test::More;

BEGIN {
    plan skip_all => "Set TEST_MYSQL environment variable to run this test"
        unless $ENV{TEST_MYSQL};
    plan tests => 27;
};

BEGIN {
    my $dbfile = temp_filename;
    our $DRIVER = Data::Model::Driver::DBI->new(
        dsn => 'dbi:mysql:database=test',
    );
    use_ok('Mock::Basic');
    use_ok('Mock::Index');
    use_ok('Mock::ColumnSugar');
    use_ok('Mock::ColumnSugar2');
    use_ok('Mock::SchemaOptions');
}


my $mock = Mock::Basic->new;

my @user = $mock->get_schema('user')->sql->as_sql;
is scalar(@user), 1;
is($user[0], "CREATE TABLE user (
    id              CHAR(255)      ,
    name            CHAR(255)      ,
    PRIMARY KEY (id)
)");

my @bookmark = $mock->get_schema('bookmark')->sql->as_sql;
is scalar(@bookmark), 1;
is($bookmark[0], "CREATE TABLE bookmark (
    id              INT             AUTO_INCREMENT,
    url             CHAR(255)      ,
    PRIMARY KEY (id),
    UNIQUE url (url)
)");

my @bookmark_user = $mock->get_schema('bookmark_user')->sql->as_sql;
is scalar(@bookmark_user), 1;
is($bookmark_user[0], "CREATE TABLE bookmark_user (
    bookmark_id     CHAR(100)      ,
    user_id         CHAR(100)      ,
    PRIMARY KEY (bookmark_id, user_id),
    INDEX user_id (user_id)
)");



$mock = Mock::Index->new;

my @multi_keys = $mock->get_schema('multi_keys')->sql->as_sql;
is scalar(@multi_keys), 1;
is($multi_keys[0], "CREATE TABLE multi_keys (
    key1            CHAR(255)      ,
    key2            CHAR(255)      ,
    key3            CHAR(255)      ,
    PRIMARY KEY (key1, key2, key3)
)");

my @multi_unique = $mock->get_schema('multi_unique')->sql->as_sql;
is scalar(@multi_unique), 1;
is($multi_unique[0], "CREATE TABLE multi_unique (
    c_key           INT             AUTO_INCREMENT,
    unq1            CHAR(255)      ,
    unq2            CHAR(255)      ,
    unq3            CHAR(255)      ,
    PRIMARY KEY (c_key),
    UNIQUE unq (unq1, unq2, unq3)
)");

my @multi_index = $mock->get_schema('multi_index')->sql->as_sql;
is scalar(@multi_index), 1;
is($multi_index[0], "CREATE TABLE multi_index (
    c_key           INT             AUTO_INCREMENT,
    idx1            CHAR(255)      ,
    idx2            CHAR(255)      ,
    idx3            CHAR(255)      ,
    PRIMARY KEY (c_key),
    INDEX idx (idx1, idx2, idx3)
)");


$mock = Mock::ColumnSugar->new;

my @author = $mock->get_schema('author')->sql->as_sql;
is scalar(@author), 1;
is($author[0], "CREATE TABLE author (
    id              INT             UNSIGNED NOT NULL AUTO_INCREMENT,
    name            VARCHAR(128)    NOT NULL,
    PRIMARY KEY (id)
)");

my @book = $mock->get_schema('book')->sql->as_sql;
is scalar(@book), 1;
is($book[0], "CREATE TABLE book (
    id              INT             UNSIGNED NOT NULL AUTO_INCREMENT,
    author_id       INT             UNSIGNED NOT NULL,
    sub_author_id   INT             UNSIGNED,
    title           VARCHAR(255)    NOT NULL,
    description     TEXT            NOT NULL DEFAULT 'not yet writing',
    recommend       TEXT           ,
    PRIMARY KEY (id),
    INDEX author_id (author_id)
)");


$mock = Mock::ColumnSugar2->new;
my @author2 = $mock->get_schema('author')->sql->as_sql;
is scalar(@author2), 1;
is($author2[0], "CREATE TABLE author (
    id              CHAR(32)        NOT NULL,
    name            VARCHAR(128)    NOT NULL,
    PRIMARY KEY (id)
)");


$mock = Mock::SchemaOptions->new;
my @unq = $mock->get_schema('unq')->sql->as_sql;
is scalar(@unq), 1;
is($unq[0], "CREATE TABLE unq (
    id1             CHAR(255)      ,
    id2             CHAR(255)      ,
    UNIQUE unq_1 (id1, id2),
    UNIQUE unq_2 (id2, id1)
) TYPE=InnoDB");

my @unq2 = $mock->get_schema('unq2')->sql->as_sql;
is scalar(@unq2), 1;
is($unq2[0], "CREATE TABLE unq2 (
    id1             CHAR(255)      ,
    id2             CHAR(255)      ,
    UNIQUE unq_2 (id2, id1),
    UNIQUE unq_1 (id1, id2)
) TYPE=InnoDB");
