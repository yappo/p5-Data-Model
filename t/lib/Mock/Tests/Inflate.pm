package Mock::Tests::Inflate;
use t::Utils;
use base 'Test::Class';
use Mock::Tests;
use Test::More;

use Encode ();
use URI;

sub t_01_all_utf8 : Tests(14) {
    use utf8;

    my $set = mock->set( all_utf8 => { name => '大沢和宏', nickname => 'Ｙａｐｐｏ' } );
    isa_ok $set, mock_class."::all_utf8";
    ok Encode::is_utf8( $set->name ), 'is_utf8';
    ok Encode::is_utf8( $set->nickname ), 'is_utf8';

    ok !Encode::is_utf8( $set->get_original_column('name') ), 'is_not_utf8';
    ok !Encode::is_utf8( $set->get_original_column('nickname') ), 'is_not_utf8';

    is $set->name, '大沢和宏', 'name';
    is $set->nickname, 'Ｙａｐｐｏ', 'nickname';

    my($get) = do {
        no utf8;
        mock->get( all_utf8 => { where => [ nickname => 'Ｙａｐｐｏ' ] } );
    };
    isa_ok $get, mock_class."::all_utf8";
    ok Encode::is_utf8( $get->name ), 'is_utf8';
    ok Encode::is_utf8( $get->nickname ), 'is_utf8';

    ok !Encode::is_utf8( $get->get_original_column('name') ), 'is_not_utf8';
    ok !Encode::is_utf8( $get->get_original_column('nickname') ), 'is_not_utf8';

    is $get->name, '大沢和宏', 'name';
    is $get->nickname, 'Ｙａｐｐｏ', 'nickname';
}

sub t_02_part_of_utf8 : Tests(16) {
    my $nickname = 'Ｙａｐｐｏ';
    use utf8;

    my $set = mock->set( part_of_utf8 => { name => '大沢和宏', nickname => $nickname } );
    isa_ok $set, mock_class."::part_of_utf8";
    ok Encode::is_utf8( $set->name ), 'is_utf8';
    ok !Encode::is_utf8( $set->nickname ), 'is_utf8';

    ok !Encode::is_utf8( $set->get_original_column('name') ), 'is_not_utf8';
    ok !Encode::is_utf8( $set->get_original_column('nickname') ), 'is_not_utf8';

    is $set->name, '大沢和宏', 'name';
    is $set->nickname, $nickname, 'nickname';
    isnt $set->nickname, 'Ｙａｐｐｏ', 'isnt nickname';

    my($get) = do {
        no utf8;
        mock->get( part_of_utf8 => { where => [ nickname => $nickname ] } );
    };
    isa_ok $get, mock_class."::part_of_utf8";
    ok Encode::is_utf8( $get->name ), 'is_utf8';
    ok !Encode::is_utf8( $get->nickname ), 'is_utf8';

    ok !Encode::is_utf8( $get->get_original_column('name') ), 'is_not_utf8';
    ok !Encode::is_utf8( $get->get_original_column('nickname') ), 'is_not_utf8';

    is $get->name, '大沢和宏', 'name';
    is $get->nickname, $nickname, 'nickname';
    isnt $get->nickname, 'Ｙａｐｐｏ', 'isnt nickname';
}

sub t_03_utf8_key : Tests(14) {
    use utf8;

    my $set = mock->set( utf8_key => '大沢和宏' => { nickname => 'Yappo' } );
    isa_ok $set, mock_class."::utf8_key";
    ok Encode::is_utf8( $set->name ), 'is_utf8';

    ok !Encode::is_utf8( $set->get_original_column('name') ), 'is_not_utf8';

    is $set->name, '大沢和宏', 'name';
    is $set->nickname, 'Yappo', 'nickname';

    {
        no utf8;
        ok !mock->get( utf8_key => '大沢和宏' ), 'get ng';
    }
    my($get) = mock->get( utf8_key => '大沢和宏' );
    isa_ok $get, mock_class."::utf8_key";
    ok Encode::is_utf8( $get->name ), 'is_utf8';

    ok !Encode::is_utf8( $get->get_original_column('name') ), 'is_not_utf8';

    is $get->name, '大沢和宏', 'name';
    is $get->nickname, 'Yappo', 'nickname';

    {
        no utf8;
        ok !mock->delete( utf8_key => '大沢和宏' ), 'delete';
    }

    ok mock->delete( utf8_key => '大沢和宏' ), 'delete';
    ok !mock->get( utf8_key => '大沢和宏' ), 'get ng';
}


sub t_04_object_key : Tests(46) {
    use utf8;

    my $set = mock->set(
        object_key => [ Name->new( name => '大沢和宏' ) ],
        { nickname => Name->new( name => 'やっぽ' ) }
    );
    isa_ok $set, mock_class."::object_key";
    isa_ok $set->name, 'Name';
    isa_ok $set->nickname, 'Name';

    ok Encode::is_utf8( $set->name->name ), 'is_utf8';
    ok Encode::is_utf8( $set->nickname->name ), 'is_utf8';

    ok !Encode::is_utf8( $set->get_original_column('name') ), 'is_not_utf8';
    ok !Encode::is_utf8( $set->get_original_column('nickname') ), 'is_not_utf8';

    is $set->name->name, '大沢和宏', 'name';
    is $set->nickname->name, 'やっぽ', 'nickname';

    
    {
        my($get) = mock->get( object_key => [ Name->new( name => '大沢和宏' ) ] );
        isa_ok $get->name, 'Name';
        isa_ok $get->nickname, 'Name';

        ok Encode::is_utf8( $get->name->name ), 'is_utf8';
        ok Encode::is_utf8( $get->nickname->name ), 'is_utf8';

        ok !Encode::is_utf8( $get->get_original_column('name') ), 'is_not_utf8';
        ok !Encode::is_utf8( $get->get_original_column('nickname') ), 'is_not_utf8';

        is $get->name->name, '大沢和宏', 'name';
        is $get->nickname->name, 'やっぽ', 'nickname';

        $get->nickname( Name->new( name => 'ヤッポ' )  );
        $get->update;
        is $get->nickname->name, 'ヤッポ', 'nickname';
    }

    {
        my($get) = mock->get( object_key => [ Name->new( name => '大沢和宏' ) ] );
        isa_ok $get->name, 'Name';
        isa_ok $get->nickname, 'Name';

        ok Encode::is_utf8( $get->name->name ), 'is_utf8';
        ok Encode::is_utf8( $get->nickname->name ), 'is_utf8';

        ok !Encode::is_utf8( $get->get_original_column('name') ), 'is_not_utf8';
        ok !Encode::is_utf8( $get->get_original_column('nickname') ), 'is_not_utf8';

        is $get->name->name, '大沢和宏', 'name';
        is $get->nickname->name, 'ヤッポ', 'changed nickname';
    }

    {
        ok mock->update_direct(
            object_key => [ Name->new( name => '大沢和宏' ) ],
            undef,
            {
                name     => Name->new( name => '大沢' ),
                nickname => Name->new( name => '和宏' ),
            }
        ), 'update_direct by key';

        my($get) = mock->get( object_key => [ Name->new( name => '大沢' ) ] );
        isa_ok $get->name, 'Name';
        isa_ok $get->nickname, 'Name';

        ok Encode::is_utf8( $get->name->name ), 'is_utf8';
        ok Encode::is_utf8( $get->nickname->name ), 'is_utf8';

        ok !Encode::is_utf8( $get->get_original_column('name') ), 'is_not_utf8';
        ok !Encode::is_utf8( $get->get_original_column('nickname') ), 'is_not_utf8';

        is $get->name->name, '大沢', 'name';
        is $get->nickname->name, '和宏', 'nickname';
    }

    {
        ok mock->update_direct(
            object_key => {
                index => { 
                    nickname => Name->new( name => '和宏' ),
                },
            }, {
                name     => Name->new( name => '沢' ),
                nickname => Name->new( name => '宏' ),
            }
        ), 'update_direct by index';

        my($get) = mock->get( object_key => [ Name->new( name => '沢' ) ] );
        isa_ok $get->name, 'Name';
        isa_ok $get->nickname, 'Name';

        ok Encode::is_utf8( $get->name->name ), 'is_utf8';
        ok Encode::is_utf8( $get->nickname->name ), 'is_utf8';

        ok !Encode::is_utf8( $get->get_original_column('name') ), 'is_not_utf8';
        ok !Encode::is_utf8( $get->get_original_column('nickname') ), 'is_not_utf8';

        is $get->name->name, '沢', 'name';
        is $get->nickname->name, '宏', 'nickname';
    }

    ok mock->delete( object_key => [ Name->new( name => '沢' ) ] ), 'delete';
    ok !mock->get( object_key => [ Name->new( name => '沢' ) ] ), 'get ng';
}

sub t_05_uri : Tests(8) {
    my $set = mock->set(
        uri => { uri => URI->new( 'http://example.com/' ) }
    );
    isa_ok $set, mock_class."::uri";
    isa_ok $set->uri, 'URI';
    is $set->uri->host, 'example.com', 'is example.com';

    my($get) = mock->get( uri => { index => { uri_idx => [ URI->new('http://example.com/') ] } } );
    isa_ok $get, mock_class."::uri";
    isa_ok $get->uri, 'URI';
    is $get->uri->host, 'example.com', 'is example.com';
    ok $get->delete, 'delete';

    ok !mock->get( uri => { index => { uri_idx => [ URI->new('http://example.com/') ] } } ), 'get ng';
}

sub t_06_name_type : Tests(8) {
    my $set = mock->set(
        name_type => { name => Name->new( name => 'yappo' ) }
    );
    isa_ok $set, mock_class."::name_type";
    isa_ok $set->name, 'Name';
    is $set->name->name, 'yappo', 'is yappo';

    my($get) = mock->get( name_type => { index => { name_idx => [ Name->new( name => 'yappo' ) ] } } );
    isa_ok $get, mock_class."::name_type";
    isa_ok $get->name, 'Name';
    is $get->name->name, 'yappo', 'is yappo';
    ok $get->delete, 'delete';

    ok !mock->get( name_type => { index => { name_idx => [ Name->new( name => 'yappo' ) ] } } ), 'get ng';
}

1;
