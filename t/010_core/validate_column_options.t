use t::Utils;
use Test::More tests => 4;
use Test::Exception;

throws_ok {
    package Schema;
    use base 'Data::Model';
    use Data::Model::Schema;
    use Data::Model::Driver::Memory;

    base_driver( Data::Model::Driver::Memory->new(
    ) );
    install_model model1 => schema {
        column clm => 'int' => { unsigned => 1, required => +{} };
    };
} qr/ to Data::Model::Schema::Properties::add_column was a 'hashref', which is not one of the allowed types: scalar undef[^\n]*(\n+[^\n]+)+validate_column_options\.t/sm;

throws_ok {
    package Schema;
    use base 'Data::Model';
    use Data::Model::Schema;
    use Data::Model::Driver::Memory;

    base_driver( Data::Model::Driver::Memory->new(
    ) );
    install_model model2 => schema {
        column clm => 'int' => { unsigned => +{} };
    };
} qr/ to Data::Model::Schema::Properties::add_column was a 'hashref', which is not one of the allowed types: scalar undef[^\n]*(\n+[^\n]+)+validate_column_options\.t/sm;

throws_ok {
    package Schema;
    use base 'Data::Model';
    use Data::Model::Schema;
    use Data::Model::Driver::Memory;

    base_driver( Data::Model::Driver::Memory->new(
    ) );
    install_model model3 => schema {
        column clm => 'int' => { size => 'x' };
    };
} qr/ to Data::Model::Schema::Properties::add_column did not pass regex check[^\n]*(\n+[^\n]+)+validate_column_options\.t/sm;

throws_ok {
    package Schema;
    use base 'Data::Model';
    use Data::Model::Schema;
    use Data::Model::Driver::Memory;

    base_driver( Data::Model::Driver::Memory->new(
    ) );
    install_model model4 => schema {
        column clm => 'int' => { wtf => 1 };
    };
} qr/ to Data::Model::Schema::Properties::add_column but was not listed in the validation options: wtf[^\n]*(\n+[^\n]+)+validate_column_options\.t/sm;

1;

