use t::Utils;
use Test::More tests => 2;

use Mock::Simple;

my $simple = Mock::Simple::user->new;
isa_ok $simple, 'Mock::Simple::user';

my $auto_increment = Mock::Simple::user_id->new;
isa_ok $auto_increment, 'Mock::Simple::user_id';
