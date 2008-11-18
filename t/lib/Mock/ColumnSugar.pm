package Mock::ColumnSugar;
use strict;
use warnings;
use base 'Data::Model';
use Data::Model::Schema sugar => 'column_sugar';

column_sugar 'author.id'
    => 'int' => +{
        unsigned => 1,
        require  => 1,
    };
column_sugar 'author.name'
    => 'varchar' => +{
        size    => 128,
        require => 1,
    };

column_sugar 'book.id'
    => 'int' => +{
        unsigned => 1,
        require  => 1,
    };
column_sugar 'book.title'
    => 'varchar' => +{
        size    => 255,
        require => 1,
    };
column_sugar 'book.description'
    => 'text' => +{
        require => 1,
        default => 'not yet writing'
    };
column_sugar 'book.recommend'
    => 'text';


install_model author => schema {
    driver $main::DRIVER;
    key 'id';

    column 'author.id' => { auto_increment => 1 };
    column 'author.name';
};

install_model book => schema {
    driver $main::DRIVER;
    key 'id';
    index 'author_id';

    column 'book.id'   => { auto_increment => 1 };
    column 'author.id';
    column 'author.id' => 'sub_author_id' => { require => 0 };
    column 'book.title';
    column 'book.description';
    column 'book.recommend';
};

1;
