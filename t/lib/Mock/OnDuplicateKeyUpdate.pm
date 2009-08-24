package Mock::OnDuplicateKeyUpdate;
use strict;
use warnings;
use base 'Data::Model';
use Data::Model::Schema;

install_model simple => schema {
    driver $main::DRIVER;
    key 'k';
    columns qw/ k v /;
};
install_model simple2 => schema {
    driver $main::DRIVER;
    key 'k';
    columns qw/ k v1 v2 /;
};

install_model multi_key => schema {
    driver $main::DRIVER;
    key [qw/ k1 k2 /];
    columns qw/ k1 k2 v /;
};

install_model simple_unique => schema {
    driver $main::DRIVER;
    unique 'k';
    columns qw/ k v /;
};
install_model simple_unique2 => schema {
    driver $main::DRIVER;
    unique 'k';
    columns qw/ k v1 v2 /;
};

install_model multi_unique => schema {
    driver $main::DRIVER;
    unique u1 =>  [qw/ k1 k2 /];
    columns qw/ k1 k2 v /;
};

install_model not_has_key => schema {
    driver $main::DRIVER;
    columns qw/ k1 k2 v /;
};

install_model multi_unique_key => schema {
    driver $main::DRIVER;
    unique 'k1';
    unique 'k2';
    columns qw/ k1 k2 v /;
};

install_model key_with_unique_key => schema {
    driver $main::DRIVER;
    key 'k1';
    unique 'k2';
    columns qw/ k1 k2 v /;
};

1;

