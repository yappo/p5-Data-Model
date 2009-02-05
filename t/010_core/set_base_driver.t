use t::Utils;
use Test::More tests => 11;

use Mock::SetBaseDriver;

my $model = 'Mock::SetBaseDriver';

my $base_driver = $model->get_base_driver;
isa_ok $base_driver, 'Data::Model::Driver::Memory';

is $model->get_driver('user'), $base_driver, 'user driver ok';
is $model->get_driver('bookmark'), $base_driver, 'bookmark driver ok';
is $model->get_driver('bookmark_user'), $base_driver, 'bookmark_user driver ok';

my $new_driver = Data::Model::Driver::Memory->new;
ok($base_driver != $new_driver, 'create new driver instance');

$model->set_base_driver($new_driver);
is $model->get_driver('user'), $base_driver, 'user driver ok';
is $model->get_driver('bookmark'), $base_driver, 'bookmark driver ok';
is $model->get_driver('bookmark_user'), $base_driver, 'bookmark_user driver ok';

$model->clear_all_drivers;
$model->set_base_driver($new_driver);
is $model->get_driver('user'), $new_driver, 'user driver ok';
is $model->get_driver('bookmark'), $new_driver, 'bookmark driver ok';
is $model->get_driver('bookmark_user'), $new_driver, 'bookmark_user driver ok';
