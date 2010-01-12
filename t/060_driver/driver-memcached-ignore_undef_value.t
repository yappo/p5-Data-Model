use strict;
use warnings;
use t::Utils;
use Test::More tests => 4;

use Data::Model::Schema::Properties;
use Data::Model::Driver::Memcached;

do {
    my $driver = Data::Model::Driver::Memcached->new( ignore_undef_value => 1 );
    my $schema = Data::Model::Schema::Properties->new();
    $schema->add_column($_) for qw/ foo bar baz /;
    my $hash = {
        foo => 'one',
        bar => 'two',
        baz => undef,
    };

    my $data = $driver->strip_undefvalue($schema, $hash);
    is_deeply($hash, { foo => 'one', bar => 'two', baz => undef });
    is_deeply($data, { foo => 'one', bar => 'two' });
    $hash = $driver->revert_undefvalue($schema, $data);
    is_deeply($hash, { foo => 'one', bar => 'two', baz => undef });
    is_deeply($data, { foo => 'one', bar => 'two' });
};
