use t::Utils;
use Mock::Tests::Index;
use Data::Model::Driver::Memory;

BEGIN {
    our $DRIVER = Data::Model::Driver::Memory->new;
    eval "use Mock::Index"; $@ and die $@;
}

my $mock = Mock::Index->new;
Mock::Tests::Index->set_mock($mock);
Mock::Tests::Index->runtests;
