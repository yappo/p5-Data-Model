use t::Utils;
use Test::More tests => 9;
use Test::Exception;

{
    package Schema;
    use base 'Data::Model';
    use Data::Model::Schema;
    use Data::Model::Driver::Memory;

    base_driver( Data::Model::Driver::Memory->new(
    ) );
    install_model model => schema {
        key 'id';
        unique 'unq';
        index 'name';
        columns qw/id unq name nickname/;
    };
}

my $obj = Schema->new;
$obj->set(
    model => {
        id       => 1,
        unq      => 'u1',
        name     => 'osawa',
        nickname => 'yappo',
    }
);

lives_ok {
    local $Data::Model::RUN_VALIDATION = 0;
    $obj->get('model' => { name => 'osawa' });
} 'local $Data::Model::RUN_VALIDATION = 0';

throws_ok {
    $obj->get('model' => { name => 'osawa' });
} qr/but was not listed in the validation options: name/;

throws_ok {
    $obj->get('model' => { index => { nickname => 'osawa' } });
} qr/did not pass the 'has_index_name' callback/;

throws_ok {
    $obj->get('model' => { index => { bar => 'osawa' } });
} qr/did not pass the 'has_index_name' callback/;


lives_ok {
    my($ret) = $obj->get('model' => { index => { name => 'osawa' } });
    is $ret->id, 1, 'get by index';
} 'has an index name';

lives_ok {
    my($ret) = $obj->get('model' => { index => { unq => 'u1' } });
    is $ret->id, 1, 'get by unique index';
} 'has an unique index name';

throws_ok {
    $obj->get('model' => { index => { unq => 'u1', foo => 2 } });
} qr/did not pass the 'has_index_name' callback/;
