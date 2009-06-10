use inc::Module::Install;
name 'Data-Model';
all_from 'lib/Data/Model.pm';

requires 'Carp';
requires 'Class::Trigger';
requires 'Params::Validate';
requires 'Storable';
requires 'DBI';
requires 'DBD::SQLite';

tests 't/*.t t/*/*.t';
author_tests 'xt';

build_requires 'Test::Class';
build_requires 'Test::Exception';
build_requires 'Test::More';
build_requires 'Path::Class';

test_requires 'URI';
test_requires 'IO::Socket::INET';

use_test_base;
auto_include;
WriteAll;
