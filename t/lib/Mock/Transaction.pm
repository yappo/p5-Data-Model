package Mock::Transaction;
use strict;
use warnings;
use base 'Data::Model';
use Data::Model::Schema;

base_driver $main::DRIVER;
install_model user => schema {
    key 'id';
    index 'name';

    column id => int => { auto_increment => 1 };
    columns qw/ name nickname /;

    schema_options create_sql_attributes => {
        mysql => 'ENGINE=InnoDB',
    };
};

install_model user2 => schema {
    key 'name';

    columns qw/ name nickname /;

    schema_options create_sql_attributes => {
        mysql => 'ENGINE=InnoDB',
    };
};

install_model user3 => schema {
    key 'name';

    columns qw/ name nickname /;

    schema_options create_sql_attributes => {
        mysql => 'ENGINE=InnoDB',
    };
};

install_model is_base => schema {
    driver $main::DRIVER;
    key 'id';

    columns qw/ id name nickname /;

    schema_options create_sql_attributes => {
        mysql => 'ENGINE=InnoDB',
    };
};

install_model isnot_base => schema {
    my $class = ref($main::DRIVER);
    driver bless { %{ $main::DRIVER } }, $class;

    key 'id';

    columns qw/ id name nickname /;

    schema_options create_sql_attributes => {
        mysql => 'ENGINE=InnoDB',
    };
};

1;

