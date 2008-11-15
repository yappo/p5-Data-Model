use t::Utils;
use Mock::Tests::Basic;
use Data::Model::Driver::Memory;

BEGIN {
    our $DRIVER = Data::Model::Driver::Memory->new;
    eval "use Mock::Basic"; $@ and die $@;
}

my $mock = Mock::Basic->new;
Mock::Tests::Basic->set_mock($mock);
Mock::Tests::Basic->runtests;
