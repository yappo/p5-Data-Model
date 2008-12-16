package Mock::AliasColumn;
use strict;
use warnings;
use base 'Data::Model';
use Data::Model::Schema;


{
    package Name;
    sub new {
        my($class, %args) = @_;
        bless { %args }, $class;
    }
    sub name { shift->{name} };
}

install_model name => schema {
    driver $main::DRIVER;
    key 'id';

    column id
        => int => {
            auto_increment => 1,
        };
    columns qw( name nickname );

    alias_column name     => 'name_name';
    alias_column nickname => 'nickname_name'
        => {
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

install_model utf8 => schema {
    driver $main::DRIVER;
    key 'id';

    column id
        => int => {
            auto_increment => 1,
        };
    columns qw( name nickname );

    alias_column name     => 'utf8_name' => { is_utf8 => 1 };
    alias_column nickname => 'utf8_nickname'
        => {
            is_utf8 => 1,
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
        };
    alias_column uri => uri_obj
        => {
            inflate => 'URI',
       };
};


1;
