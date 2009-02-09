use strict;
use warnings;
use t::Utils;
use Test::More tests => 2;

{
    package Schema;
    use base 'Data::Model';
    use Data::Model::Schema;

    install_model model => schema {
        key 'id';
        columns qw/id name nickname/;
        add_method description => sub {
            my $obj = shift;
            sprintf q{%s: %s's nickname is %s}, $obj->id, $obj->name, $obj->nickname;
        };
    };
}

my $obj = Schema::model->new(
    Schema->new, {
    id       => 1,
    name     => 'osawa',
    nickname => 'yappo',
});
isa_ok $obj, 'Schema::model';
is $obj->description, q{1: osawa's nickname is yappo};
