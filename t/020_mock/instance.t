use t::Utils;
use Test::More tests => 3;

use Mock::Basic;

my $user = Mock::Basic::user->new;
isa_ok $user, 'Mock::Basic::user';
my $bookmark = Mock::Basic::bookmark->new;
isa_ok $bookmark, 'Mock::Basic::bookmark';
my $bookmark_user = Mock::Basic::bookmark_user->new;
isa_ok $bookmark_user, 'Mock::Basic::bookmark_user';
