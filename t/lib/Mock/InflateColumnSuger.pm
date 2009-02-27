package Mock::InflateColumnSuger;
use strict;
use warnings;
use base 'Data::Model';
use Data::Model::Schema;

{
    package TestDat;
    sub new {
        my($class, %args) = @_;
        bless { %args }, $class;
    }
    sub data { shift->{data} };
}

column_sugar 'tbl.id'
    => int => +{
        auto_increment => 1,
    };
column_sugar 'tbl.name'
    => char => {};
column_sugar 'tbl.data'
    => char => {
        inflate => sub {
            my $value = shift;
            TestDat->new( data => $value );
        },
        deflate => sub {
            my $obj = shift;
            $obj->data;
        },
    };


install_model tbl => schema {
    driver $main::DRIVER;
    key 'id';

    column      'tbl.id';
    utf8_column 'tbl.name';
    column      'tbl.data';
};

install_model tbl2 => schema {
    driver $main::DRIVER;
    key 'id';

    column      'tbl.id'   => 'id';
    utf8_column 'tbl.name' => 'name2';
    column      'tbl.data' => 'data2';
};

1;

