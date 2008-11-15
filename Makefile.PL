use inc::Module::Install;
name 'Data-Model';
all_from 'lib/Data/Model.pm';

# requires '';
requires 'Carp';
requires 'Class::Trigger';
# DBI

tests 't/*.t t/*/*.t';
author_tests 'xt';

build_requires 'Test::Class';
build_requires 'Test::More';
build_requires 'Path::Class';


use_test_base;
auto_include;
WriteAll;
