package Mock::Basic;
use strict;
use warnings;
use base 'Data::Model';
use Data::Model::Schema;

install_model user => schema {
    driver $main::DRIVER;
    key 'id';
    columns qw/id name/;
};

install_model bookmark => schema {
    driver $main::DRIVER;
    key 'id';
    unique 'url';

    column id
        => int => {
            auto_increment => 1,
        };

    column 'url';
};

install_model bookmark_user => schema {
    my $columns = [qw/ bookmark_id user_id /];
    driver $main::DRIVER;
    key $columns;
    index 'user_id';

    columns @{ $columns };
};

sub as_sqls {
    [
        "CREATE TABLE user ( id CHAR(255), name CHAR(255), PRIMARY KEY ( id ) )",
        "CREATE TABLE bookmark ( id INTEGER NOT NULL PRIMARY KEY, url CHAR(255), UNIQUE (url) )",
        "CREATE TABLE bookmark_user ( bookmark_id CHAR(255), user_id CHAR(255), PRIMARY KEY ( bookmark_id, user_id ) )",
        "CREATE INDEX user_id ON bookmark_user(user_id)",
    ];
}


1;
