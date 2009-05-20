use t::Utils;
use Test::More tests => 2;
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
        index 'name';
        columns qw/id name nickname/;
    };
}

my $obj = Schema->new;
$obj->set(
    model => {
        id       => 1,
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
