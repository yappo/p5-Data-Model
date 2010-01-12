use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');
__DATA__
Kazuhiro Osawa
yappo <at> shibuya <döt> pl
Data::Model
mixin
DBI
Mapper
Memcached
SQLite
Memcached
memcached
tokuhirom
Trott
ACKNOWLEDGEMENTS
DSL
InnoDB
ParamsValidate
ascii
inflateing
unicode
utf
zerofill
DataModel
ORM
mapper
fallback
groonga
kai
DBD
JPerl
