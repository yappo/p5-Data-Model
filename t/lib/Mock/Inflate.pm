package Mock::Inflate;
use strict;
use warnings;
use base 'Data::Model';
use Data::Model::Schema;
use Data::Model::Schema::Inflate;

install_model all_utf8 => schema {
    driver $main::DRIVER;
    key 'id';

    column id
        => int => {
            auto_increment => 1,
        };
    utf8_columns qw( name nickname );
};

install_model part_of_utf8 => schema {
    driver $main::DRIVER;
    key 'id';

    column id
        => int => {
            auto_increment => 1,
        };

    utf8_column name
        => char => { size => 100 };

    column nickname
        => char => { size => 100 };
};

install_model utf8_key => schema {
    driver $main::DRIVER;
    key 'name';

    utf8_column name
        => char => { size => 100 };
    column nickname
        => char => { size => 100 };
};

{
    package Name;
    sub new {
        my($class, %args) = @_;
        bless { %args }, $class;
    }
    sub name { shift->{name} };
}


install_model object_key => schema {
    driver $main::DRIVER;
    key 'name';
    index 'nickname';

    utf8_column name
        => char => {
            inflate => sub {
                my $value = shift;
                Name->new( name => $value );
            },
            deflate => sub {
                my $obj = shift;
                $obj->name;
            },
        };
    utf8_column nickname
        => char => {
            inflate => sub {
                my $value = shift;
                Name->new( name => $value );
            },
            deflate => sub {
                my $obj = shift;
                $obj->name;
            },
        };
};


install_model uri => schema {
    driver $main::DRIVER;
    key 'id';
    index uri_idx => 'uri';

    column id
        => int => {
            auto_increment => 1,
        };
    column uri
        => char => {
            size    => 200,
            inflate => 'URI',
        };
};


inflate_type NAME => {
    inflate => sub {
        Name->new( name => shift );
    },
    deflate => sub {
        shift->name;
    },
};
install_model name_type => schema {
    driver $main::DRIVER;
    key 'id';
    index name_idx => 'name';

    column id
        => int => {
            auto_increment => 1,
        };
    column name
        => char => {
            size    => 200,
            inflate => 'NAME',
        };
};

1;
