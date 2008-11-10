use t::Utils;
use Mock::Tests::Basic;
use Test::More tests => Mock::Tests::Basic->tests;

our $DBFILE = temp_filename;
eval "use Mock::DBI::Basic"; $@ and die $@;
setup_sqlite( Mock::DBI::Basic->as_sqls, $DBFILE );

my $mock = Mock::DBI::Basic->new;
Mock::Tests::Basic->set_mock($mock);
Mock::Tests::Basic->runtests;

__END__

use t::Utils;
use Test::More tests => 30;

use Mock::DBI::Basic;

my $mock = Mock::DBI::Basic->new;

my $ret1 = $mock->set( user => 'yappo', { name => 'Kazuhiro Osawa' } );
isa_ok $ret1, 'Mock::DBI::Basic::user';
is $ret1->id, 'yappo';
is $ret1->name, 'Kazuhiro Osawa';

