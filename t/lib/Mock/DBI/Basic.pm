package Mock::DBI::Basic;
use strict;
use warnings;
use base 'Data::Model';
use Data::Model::Schema;
use Data::Model::Driver::DBI;


my $dbi = Data::Model::Driver::DBI->new(
    dsn => 'dbi:SQLite:dbname=' . $main::DBFILE,
    username => 'username',
    password => 'password',
);

install_model user => schema {
    driver $dbi;
    key 'id';
    columns qw/id name/;
};

install_model bookmark => schema {
    driver $dbi;
    key 'id';

    column id
        => int => {
            auto_increment => 1,
        };

    column 'url';
};

install_model bookmark_user => schema {
    my $columns = [qw/ bookmark_id user_id /];
    driver $dbi;
    key $columns;
    columns @{ $columns };
    index 'user_id';
};

sub as_sqls {
    [
        "CREATE TABLE user ( id CHAR(255), name CHAR(255), PRIMARY KEY ( id ) )",
        "CREATE TABLE bookmark_user ( bookmark_id CHAR(255), user_id CHAR(255), PRIMARY KEY ( bookmark_id, user_id ) )",
    ];
}


1;
