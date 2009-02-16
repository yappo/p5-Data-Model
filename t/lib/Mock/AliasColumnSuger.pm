package Mock::AliasColumnSuger;
use strict;
use warnings;
use base 'Data::Model';
use Data::Model::Schema;

column_sugar 'name.id'
    => int => +{
        auto_increment => 1,
    };
column_sugar 'name.name'
    => char => +{
        alias => {
            name_name => {},
        },
    };
column_sugar 'name.nickname'
    => char => +{
        alias => {
            nickname_name => {
                inflate => sub {
                    my $value = shift;
                    Name->new( name => $value );
                },
                deflate => sub {
                    my $obj = shift;
                    $obj->name;
                },
            },
        },
    };
column_sugar 'utf8.name'
    => char => +{
        alias => {
            utf8_name => { is_utf8 => 1 },
        },
    };
column_sugar 'utf8.nickname'
    => char => +{
        alias => {
            utf8_nickname => {
                is_utf8 => 1,
                inflate => sub {
                    my $value = shift;
                    Name->new( name => $value );
                },
                deflate => sub {
                    my $obj = shift;
                    $obj->name;
                },
            },
        },
    };

column_sugar 'uri.uri'
    => char => +{
        size  => 200,
        alias => {
            uri_obj => {
                is_utf8 => 1,
                inflate => 'URI',
            }
        }
    };

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

    column 'name.id';
    column 'name.name';
    column 'name.nickname';
};

install_model utf8 => schema {
    driver $main::DRIVER;
    key 'id';

    column 'name.id' => 'id';
    column 'utf8.name';
    column 'utf8.nickname';
};

install_model uri => schema {
    driver $main::DRIVER;
    key 'id';
    index uri_idx => 'uri';

    column 'name.id' => 'id';
    column 'uri.uri';
};


use Data::Model::Schema::Inflate;

# aliased key test
inflate_type PREFIX => {
    inflate => sub {
        my $val = $_[0];
        $val =~ s/^.......//;
        $val;
    },
    deflate => sub { 'prefix_' . $_[0] },
};

column_sugar 'keytest.c_key'
    => char => {
        require => 1,
        size    => 16,
        deflate => sub {
            ($_[0] =~ /^prefix_/) ? $_[0] : 'prefix_' . $_[0];
        },
        alias   => {
            key_noprefix => {
                inflate => 'PREFIX',
            },
        },
    };

column_sugar 'keytest.data'
    => char => {
        size => 100,
    };

install_model keytest => schema {
    driver $main::DRIVER;
    key 'c_key';

    column 'keytest.c_key';
    column 'keytest.data';
};

1;
