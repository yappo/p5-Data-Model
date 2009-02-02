use strict;
use warnings;
use lib '.';
use Test::More;

use Data::Model::Schema::Inflate;

eval q{ use Data::UUID };
plan skip_all => "Data::UUID is not installed" if $@;
plan tests => 3;

use_ok 'Data::Model::Schema::Inflate::UUID';

my $id  = $Data::Model::Schema::Inflate::UUID::GEN->create;
my $str = $Data::Model::Schema::Inflate::UUID::GEN->to_string($id);

is(Data::Model::Schema::Inflate->get_inflate('UUID')->($id),
    $str, 'inflate');
is(Data::Model::Schema::Inflate->get_deflate('UUID')->($str),
    $id, 'deflate');


