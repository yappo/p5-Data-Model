package Mock::Tests::AliasColumnSugerRename;
use t::Utils;
use base 'Test::Class';
use Mock::Tests;
use Test::More;

use URI;

sub t_01_uri : Tests(10) {
    my $set = mock->set( uri => { uri => 'http://example.com/foo/?bar=baz' } );
    isa_ok $set, mock_class."::uri";
    isa_ok $set->uri_object, 'URI';

    is $set->uri, 'http://example.com/foo/?bar=baz', 'uri';
    is $set->uri_object->host, 'example.com', 'uri host';

    is $set->uri('http://example.org/'), 'http://example.org/', 'set';
    is $set->uri, 'http://example.org/', 'uri';
    is $set->uri_object->host, 'example.org', 'uri host';

    is $set->uri_object(URI->new('http://example.net/'))->host, 'example.net', 'alias set';
    is $set->uri, 'http://example.net/', 'uri';
    is $set->uri_object->host, 'example.net', 'uri host';
}

1;
