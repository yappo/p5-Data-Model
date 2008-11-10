use t::Utils;
use Mock::Tests::Basic;
use Mock::Memory::Basic;

my $mock = Mock::Memory::Basic->new;
Mock::Tests::Basic->set_mock($mock);
Mock::Tests::Basic->runtests;

__END__

my $ret = $mock->get( simple => 1 );
$ret->name( 'yapoo' );
$ret->save;

$ret->name( 'yappo' );
$mock->set( $ret );

my $ret = $mock->get( simple => 2 );
$ret->delete;

my $ret = $mock->get( simple => 3 );
$mock->delete( $ret );
