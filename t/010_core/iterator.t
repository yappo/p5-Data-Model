use strict;
use warnings;
use Test::More tests => 76;

use Data::Model::Iterator;

my @stack = qw( 1 2 );
my $itr = Data::Model::Iterator->new(
    sub { ok(1, 'do shift'); shift @stack },
    end   => sub { ok(1, 'do end') },
    reset => sub { ok(1, 'do reset') },        
);
isa_ok($itr, 'Data::Model::Iterator');
is($itr->next, 1, 'next 1');
is($itr->next, 2, 'next 2');
is($itr->next, undef, 'next is undef');
$itr->reset;
is($itr->next, 1, 'next 1');
is($itr->next, 2, 'next 2');
is($itr->next, undef, 'next is undef');
$itr->reset;
my $i = 1;
while (<$itr>) {
    is($_, $i, "Iterator overload: $i");
    ++$i;
}
$itr->reset;
ok($itr->has_next, 'has_next is true');
is(<$itr>, 1, 'Iterator overload line: 1');
ok($itr->has_next, 'has_next is true');
is(<$itr>, 2, 'Iterator overload line: 2');
ok(!$itr->has_next, 'has_next is false');
$itr->end;

@stack = qw( 1 2 );
$itr = Data::Model::Iterator->new(
    sub { ok(1, 'do shift'); shift @stack },
    end   => sub { ok(1, 'do end') },
    reset => sub { ok(1, 'do reset') },        
);
isa_ok($itr, 'Data::Model::Iterator');
ok($itr->has_next, 'has_next is true');
ok($itr->has_next, 'has_next is true');
is($itr->next, 1, 'next 1');
ok($itr->has_next, 'has_next is true');
ok($itr->has_next, 'has_next is true');
is($itr->next, 2, 'next 2');
ok(!$itr->has_next, 'has_next is false');
ok(!$itr->has_next, 'has_next is false');
is($itr->next, undef, 'next is undef');
ok(!$itr->has_next, 'has_next is false');
ok(!$itr->has_next, 'has_next is false');
$itr->reset;
ok($itr->has_next, 'has_next is true');
ok($itr->has_next, 'has_next is true');
is($itr->next, 1, 'next 1');
ok($itr->has_next, 'has_next is true');
ok($itr->has_next, 'has_next is true');
is($itr->next, 2, 'next 2');
ok(!$itr->has_next, 'has_next is false');
ok(!$itr->has_next, 'has_next is false');
is($itr->next, undef, 'next is undef');
ok(!$itr->has_next, 'has_next is false');
ok(!$itr->has_next, 'has_next is false');
$itr->end;

$itr = Data::Model::Iterator::Empty->new;
isa_ok($itr, 'Data::Model::Iterator::Empty');
ok(1, 'empty is undef') unless $itr;
is($itr, undef, 'empty is undef');
ok(!$itr, 'empty is undef');
ok(!$itr->has_next, 'has_next is false');
is($itr->next, undef, 'next is undef');
ok(!$itr->has_next, 'has_next is false');
is($itr->reset, undef, 'reset is undef');
ok(!$itr->has_next, 'has_next is false');
is($itr->next, undef, 'next is undef');
ok(!$itr->has_next, 'has_next is false');
is($itr->end, undef, 'end is undef');
while (<$itr>) {
    ok(0, 'not iteration');
}
is(<$itr>, undef, 'Iterator overload line: undef');
