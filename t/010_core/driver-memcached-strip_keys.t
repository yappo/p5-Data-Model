use strict;
use warnings;
use t::Utils;
use Test::More tests => 6;

use Data::Model::Schema::Properties;
use Data::Model::Driver::Memcached;

do {
    my $driver = Data::Model::Driver::Memcached->new( strip_keys => 1 );
    my $schema = Data::Model::Schema::Properties->new(
        key => [qw/ foo /],
    );
    my $hash = {
        foo => 'one',
        bar => 'two',
        baz => 'three',
    };

    $hash = $driver->strip_keyvalue($schema, [qw/ one /], $hash);
    is_deeply($hash, { bar => 'two', baz => 'three' });
    $hash = $driver->revert_keyvalue($schema, [qw/ one /], $hash);
    is_deeply($hash, { foo => 'one', bar => 'two', baz => 'three' });
};

do {
    my $driver = Data::Model::Driver::Memcached->new( strip_keys => 1 );
    my $schema = Data::Model::Schema::Properties->new(
        key => [qw/ foo bar /],
    );
    my $hash = {
        foo => 'one',
        bar => 'two',
        baz => 'three',
    };

    $hash = $driver->strip_keyvalue($schema, [qw/ one two /], $hash);
    is_deeply($hash, { baz => 'three' });
    $hash = $driver->revert_keyvalue($schema, [qw/ one two /], $hash);
    is_deeply($hash, { foo => 'one', bar => 'two', baz => 'three' });
};


do {
    my $driver = Data::Model::Driver::Memcached->new( strip_keys => 1 );
    my $schema = Data::Model::Schema::Properties->new(
        key => [qw/ foo bar baz /],
    );
    my $hash = {
        foo => 'one',
        bar => 'two',
        baz => 'three',
    };

    $hash = $driver->strip_keyvalue($schema, [qw/ one two three /], $hash);
    is_deeply($hash, {});
    $hash = $driver->revert_keyvalue($schema, [qw/ one two three /], $hash);
    is_deeply($hash, { foo => 'one', bar => 'two', baz => 'three' });
};
