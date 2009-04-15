use t::Utils;
use Test::More tests => 3;

use Data::Model::Mixin modules => ['+Mixin::Basic'];

my @ret = basic('arg1', 'arg2');
is($ret[0], 'mixin_basic');
is($ret[1], 'arg1');
is($ret[2], 'arg2');

