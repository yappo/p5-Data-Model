use t::Utils;
use Mock::Tests::NoKey;
use Data::Model::Driver::Memory;

BEGIN {
    my $dbfile = temp_filename;
    our $DRIVER = Data::Model::Driver::Memory->new;
    eval "use Mock::NoKey"; $@ and die $@;
}

my $mock = Mock::NoKey->new;
Mock::Tests::NoKey->set_mock($mock);
Mock::Tests::NoKey->runtests;
