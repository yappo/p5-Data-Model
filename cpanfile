requires 'perl', '5.008005';

requires 'Carp'            , '0';
requires 'Class::Trigger'  , '0';
requires 'Encode'          , '0';
requires 'Params::Validate', '0';
requires 'Storable'        , '0';
requires 'DBI'             , '0';
requires 'DBD::SQLite'     , '0';
requires 'URI'             , '0';

on test => sub {
    requires 'Test::More'      , '0.88';
    requires 'Test::Class'     , '0.34';
    requires 'Test::Exception' , '0';
    requires 'Test::More'      , '0';
    requires 'Path::Class'     , '0';

    requires 'IO::Socket::INET', '0';
};
