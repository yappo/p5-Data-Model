package Mock::Tests::AliasColumn;
use t::Utils;
use base 'Test::Class';
use Mock::Tests;
use Test::More;

use URI;

sub t_01_name : Tests(36) {
    my $set = mock->set( name => { name => 'kazuhiro osawa', nickname => 'yappo' } );
    isa_ok $set, mock_class."::name";
    isa_ok $set->nickname_name, 'Name';

    is $set->name, 'kazuhiro osawa', 'name';
    is $set->nickname, 'yappo', 'nickname';

    is $set->name_name, 'kazuhiro osawa', 'name_name';
    is $set->nickname_name->name, 'yappo', 'nickname_name';

    is $set->name('osawa'), 'osawa', 'set';
    is $set->name, 'osawa', 'name';
    is $set->name_name, 'osawa', 'name_name';

    is $set->name_name('kazuhiro'), 'kazuhiro', 'alias set';
    is $set->name, 'kazuhiro', 'name';
    is $set->name_name, 'kazuhiro', 'name_name';

    is $set->nickname('yappoppay'), 'yappoppay', 'set';
    is $set->nickname, 'yappoppay', 'nickname';
    is $set->nickname_name->name, 'yappoppay', 'nickname_name';

    is $set->nickname_name(Name->new( name => 'oppay' ))->name, 'oppay', 'alias set';
    is $set->nickname, 'oppay', 'nickname';
    is $set->nickname_name->name, 'oppay', 'nickname_name';

    my($get) = mock->get( name => 1 );
    isa_ok $get, mock_class."::name";
    isa_ok $get->nickname_name, 'Name';

    is $get->name, 'kazuhiro osawa', 'name';
    is $get->nickname, 'yappo', 'nickname';

    is $get->name_name, 'kazuhiro osawa', 'name_name';
    is $get->nickname_name->name, 'yappo', 'nickname_name';

    is $get->name_name('osawa'), 'osawa', 'set';
    is $get->name, 'osawa', 'name';
    is $get->name_name, 'osawa', 'name_name';

    is $get->name_name('kazuhiro'), 'kazuhiro', 'alias set';
    is $get->name, 'kazuhiro', 'name';
    is $get->name_name, 'kazuhiro', 'name_name';

    is $get->nickname('yappoppay'), 'yappoppay', 'set';
    is $get->nickname, 'yappoppay', 'nickname';
    is $get->nickname_name->name, 'yappoppay', 'nickname_name';

    is $get->nickname_name(Name->new( name => 'oppay' ))->name, 'oppay', 'alias set';
    is $get->nickname, 'oppay', 'nickname';
    is $get->nickname_name->name, 'oppay', 'nickname_name';
}

sub t_02_utf8: Tests(44) {
    my $set = mock->set( utf8 => { name => '大沢和宏', nickname => 'ＹＡＰＰＯ' } );
    isa_ok $set, mock_class."::utf8";
    isa_ok $set->utf8_nickname, 'Name';

    is $set->name, '大沢和宏', 'name';
    is $set->nickname, 'ＹＡＰＰＯ', 'nickname';


    {
        use utf8;
        is $set->utf8_name, '大沢和宏', 'utf8_name';
        is $set->utf8_nickname->name, 'ＹＡＰＰＯ', 'utf8_nickname';
    }

    ok !Encode::is_utf8( $set->name ), 'is not utf8';
    ok !Encode::is_utf8( $set->nickname ), 'is not utf8';
    ok Encode::is_utf8( $set->utf8_name ), 'is utf8';
    ok Encode::is_utf8( $set->utf8_nickname->name ), 'is utf8';


    is $set->name('大沢'), '大沢', 'set';
    is $set->name, '大沢', 'name';
    {
        use utf8;
        is $set->utf8_name, '大沢', 'utf8_name';

        is $set->utf8_name('和宏'), '和宏', 'alias set';
    }
    is $set->name, '和宏', 'name';
    {
        use utf8;
        is $set->utf8_name, '和宏', 'utf8_name';
    }

    is $set->nickname('やっぽ'), 'やっぽ', 'set';
    is $set->nickname, 'やっぽ', 'nickname';
    {
        use utf8;
        is $set->utf8_nickname->name, 'やっぽ', 'utf8_nickname';

        is $set->utf8_nickname(Name->new( name => 'ヤッポ' ))->name, 'ヤッポ', 'alias set';
    }
    is $set->nickname, 'ヤッポ', 'nickname';
    {
        use utf8;
        is $set->utf8_nickname->name, 'ヤッポ', 'utf8_nickname';
    }

    my($get) = mock->set( utf8 => { name => '大沢和宏', nickname => 'ＹＡＰＰＯ' } );
    isa_ok $get, mock_class."::utf8";
    isa_ok $get->utf8_nickname, 'Name';

    is $get->name, '大沢和宏', 'name';
    is $get->nickname, 'ＹＡＰＰＯ', 'nickname';


    {
        use utf8;
        is $get->utf8_name, '大沢和宏', 'utf8_name';
        is $get->utf8_nickname->name, 'ＹＡＰＰＯ', 'utf8_nickname';
    }

    ok !Encode::is_utf8( $get->name ), 'is not utf8';
    ok !Encode::is_utf8( $get->nickname ), 'is not utf8';
    ok Encode::is_utf8( $get->utf8_name ), 'is utf8';
    ok Encode::is_utf8( $get->utf8_nickname->name ), 'is utf8';


    is $get->name('大沢'), '大沢', 'set';
    is $get->name, '大沢', 'name';
    {
        use utf8;
        is $get->utf8_name, '大沢', 'utf8_name';

        is $get->utf8_name('和宏'), '和宏', 'alias set';
    }
    is $get->name, '和宏', 'name';
    {
        use utf8;
        is $get->utf8_name, '和宏', 'utf8_name';
    }

    is $get->nickname('やっぽ'), 'やっぽ', 'set';
    is $get->nickname, 'やっぽ', 'nickname';
    {
        use utf8;
        is $get->utf8_nickname->name, 'やっぽ', 'utf8_nickname';

        is $get->utf8_nickname(Name->new( name => 'ヤッポ' ))->name, 'ヤッポ', 'alias set';
    }
    is $get->nickname, 'ヤッポ', 'nickname';
    {
        use utf8;
        is $get->utf8_nickname->name, 'ヤッポ', 'utf8_nickname';
    }
}

sub t_03_uri : Tests(10) {
    my $set = mock->set( uri => { uri => 'http://example.com/foo/?bar=baz' } );
    isa_ok $set, mock_class."::uri";
    isa_ok $set->uri_obj, 'URI';

    is $set->uri, 'http://example.com/foo/?bar=baz', 'uri';
    is $set->uri_obj->host, 'example.com', 'uri host';

    is $set->uri('http://example.org/'), 'http://example.org/', 'set';
    is $set->uri, 'http://example.org/', 'uri';
    is $set->uri_obj->host, 'example.org', 'uri host';

    is $set->uri_obj(URI->new('http://example.net/'))->host, 'example.net', 'alias set';
    is $set->uri, 'http://example.net/', 'uri';
    is $set->uri_obj->host, 'example.net', 'uri host';
}

1;

