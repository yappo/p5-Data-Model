use strict;
use warnings;
{
    package Mock::ColumnSugar2;
    use base 'Data::Model';
    use Data::Model::Schema sugar => 'column_sugar2';

    column_sugar 'author.id'
        => 'char' => +{
            size     => 32,
            require  => 1,
        };
    column_sugar 'author.name'
        => 'varchar' => +{
            size    => 128,
            require => 1,
        };
}
{
    package Mock::ColumnSugar2_2;
    use base 'Data::Model';
    use Data::Model::Schema sugar => 'column_sugar2_2';

    column_sugar 'author.id'
        => 'varchar' => +{
            size     => 32,
            require  => 1,
        };
    column_sugar 'author.name'
        => 'varchar' => +{
            size    => 128,
            require => 1,
        };
}
{
    package Mock::ColumnSugar2;

    install_model author => schema {
        driver $main::DRIVER;
        key 'id';

        column 'author.id';
        column 'author.name';
    };
}

1;
