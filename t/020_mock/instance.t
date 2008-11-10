use t::Utils;
use Test::More tests => 3;

use Mock::Memory::Basic;

my $user = Mock::Memory::Basic::user->new;
isa_ok $user, 'Mock::Memory::Basic::user';
my $bookmark = Mock::Memory::Basic::bookmark->new;
isa_ok $bookmark, 'Mock::Memory::Basic::bookmark';
my $bookmark_user = Mock::Memory::Basic::bookmark_user->new;
isa_ok $bookmark_user, 'Mock::Memory::Basic::bookmark_user';
