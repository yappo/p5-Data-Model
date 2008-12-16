package Mock::AliasColumnSugerRename;
use strict;
use warnings;
use base 'Data::Model';
use Data::Model::Schema;

column_sugar 'uri.id'
    => int => +{
        auto_increment => 1,
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

install_model uri => schema {
    driver $main::DRIVER;
    key 'id';
    index uri_idx => 'uri';

    column 'uri.id';
    column 'uri.uri' => {
        alias_rename => {
            uri_obj => 'uri_object',
        },
    };
};


1;
