package Data::Model::Schema;
use strict;
use warnings;

use Carp ();
use Data::Model::Row;
use Data::Model::Schema::Properties;

sub import {
    my($class, %args) = @_;
    my $caller = caller;

    no strict 'refs';
    for my $name (qw/ driver install_model schema column columns key index unique schema_options column_sugar /) {
        *{"$caller\::$name"} = \&$name;
    }

    my $__properties = +{
        schema       => +{},
        __process_tmp => +{
            class => $caller,
        },
    };
    no warnings 'redefine';
    *{"$caller\::__properties"} = sub { $__properties };
}

my $CALLER = undef;
sub install_model ($$;%) {
    my($name, $schema_code, %args) = @_;
    my $caller = caller;

    my $pkg = "$caller\::$name";

    my $schema = $caller->__properties->{schema}->{$name} = Data::Model::Schema::Properties->new(
        driver       => undef,
        schema_class => $caller,
        model        => $name,
        class        => $pkg,
        column       => {},
        columns      => [],
        index        => {},
        unique       => {},
        key          => [],
        foreign      => [],
        triggers     => {},
        options      => +{},
    );

    $caller->__properties->{__process_tmp}->{name} = $name;
    $CALLER = $caller;
    $schema_code->();
    unless ($schema->options->{bare_row}) {
        no strict 'refs';
        @{"$pkg\::ISA"} = ( 'Data::Model::Row' );
        _install_columns_to_class($schema);
    }
    $CALLER = undef;

    if ($schema->driver) {
        $schema->driver->init_model($name, $schema);
    }
}
sub schema (&) { shift }

sub _install_columns_to_class {
    my $schema = shift;
    while (my($column, $args) = each %{ $schema->column }) {
        no strict 'refs';
        *{ $schema->class . "::$column" } = sub {
            my $obj = shift;
            # getter
            return $obj->{column_values}->{$column} unless @_;
            # setter
            my($val, $flags) = @_;
            my $old_val = $obj->{column_values}->{$column};
            $obj->{column_values}->{$column} = $val;
            unless ($flags && ref($flags) eq 'HASH' && $flags->{no_changed_flag}) {
                $obj->{changed_cols}->{$column} = $old_val;
            }
            return $obj->{column_values}->{$column};
        };
    }
}

sub _get_model_schema {
    if ($CALLER) {
        my $caller = caller(1);
        my $name = $caller->__properties->{__process_tmp}->{name};
        return ($name, $caller->__properties->{schema}->{$name});
    }

    my $method = (caller(1))[3];
    $method =~ s/.+:://;
    local $Carp::CarpLevel = 2;
    Carp::croak "'$method' method is target internal only";
}

sub driver ($;%) {
    my($name, $schema) = _get_model_schema;
    my($driver, %args) = @_;
    $schema->driver($driver);
}

sub column ($;$;$) {
    my($name, $schema) = _get_model_schema;
    $schema->add_column(@_);
}
sub columns (@) {
    my($name, $schema) = _get_model_schema;
    my @columns = @_;
    for my $column (@columns) {
        $schema->add_column($column);
    }
}

sub key ($;%) {
    my($name, $schema) = _get_model_schema;
    $schema->add_keys(@_);
}

sub index ($;$;%) {
    my($name, $schema) = _get_model_schema;
    $schema->add_index(@_);
}

sub unique ($;$;%) {
    my($name, $schema) = _get_model_schema;
    $schema->add_unique(@_);
}

sub schema_options (@) {
    my($name, $schema) = _get_model_schema;
    $schema->add_options(@_);
}


our $COLUMN_SUGAR = +{};
sub column_sugar (@) {
    my($column, $type, $options) = @_;
    Carp::croak "usage: add_column_sugar 'table_name.column_name' => type => { args };"
        unless $column =~ /^[^\.+]+\.[^\.+]+$/;
    
    $COLUMN_SUGAR->{$column} = +{
        type    => $type    || 'char',
        options => $options || +{},
    };
}

1;

__END__

target table_name => schema {

    colmun field_name
        => char => {
            size       => 10,
            require    => 1,
            signed     => 1,
            default    => 'aaa',
            validation => Foo::Schema::Validator::Str->new(),
            auto_increment => 1,
            inflate => sub {},
            deflate => sub {},
        };

    colmun field_name_2
        => char => {
            inflate => 'uri',
            deflate => 'uri',
        };
};
