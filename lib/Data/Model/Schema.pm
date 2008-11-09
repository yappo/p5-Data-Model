package Data::Model::Schema;
use strict;
use warnings;

use Carp ();
use Data::Model::Row;

sub import {
    my($class, %args) = @_;
    my $caller = caller;

    no strict 'refs';
    for my $name (qw/ driver model schema column columns key index unique schema_options /) {
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
sub model ($$;%) {
    my($name, $schema, %args) = @_;
    my $caller = caller;

    my $pkg = "$caller\::$name";

    no strict 'refs';
    @{"$pkg\::ISA"} = ( 'Data::Model::Row' );

    $caller->__properties->{schema}->{$name} = +{
        driver   => undef,
        model    => $name,
        class    => $pkg,
        column   => {},
        index    => {},
        unique   => {},
        key      => undef,
        triggers => {},
        options  => +{},
    };

    $caller->__properties->{__process_tmp}->{name} = $name;
    $CALLER = $caller;
    $schema->();
    $CALLER = undef;
}
sub schema (&) { shift }


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
    $schema->{driver} = $driver;
}

sub _column (@) {
    my($schema, $column, $type, $options) = @_;
    no strict 'refs';
    *{ $schema->{class} . "::$column" } = sub {
        my $obj = shift;
        # getter
        return $obj->{column_values}->{$column} unless @_;

        # setter
        my($val, $flags) = @_;
        $obj->{column_values}->{$column} = $val;
        unless ($flags && ref($flags) eq 'HASH' && $flags->{no_changed_flag}) {
            $obj->{changed_cols}->{$column}++;
        }
        
        return $obj->{column_values}->{$column};
    };

    $schema->{column}->{$column} = +{
        type    => $type    || 'null',
        options => $options || +{},
    };
}
sub column ($;$;$) {
    my($name, $schema) = _get_model_schema;
    _column $schema, @_;
}
sub columns (@) {
    my($name, $schema) = _get_model_schema;
    my @columns = @_;
    for my $column (@columns) {
        _column $schema, $column;
    }
}

sub key ($;%) {
    my($name, $schema) = _get_model_schema;
    my($key, %args) = @_;
    $schema->{key} = ref($key) eq 'ARRAY' ? $key : [ $key ];
}

sub index ($;$;%) {
    my($name, $schema) = _get_model_schema;
    my($index, $columns, %args) = @_;
    my $key = $columns || $index;
    $key = [ $key ] unless ref($key) eq 'ARRAY';
    $schema->{index}->{$index} = $key;
}

sub unique ($;$;%) {
    my($name, $schema) = _get_model_schema;
    my($index, $columns, %args) = @_;
    my $key = $columns || $index;
    $key = [ $key ] unless ref($key) eq 'ARRAY';
    $schema->{unique}->{$index} = $key;
}

sub schema_options (@) {
    my($name, $schema) = _get_model_schema;
    if (ref($_[0]) eq 'HASH') {
        $schema->{options} = shift;
    } elsif (!(@_ % 2)) {
        while (my($key, $value) = splice @_, 0, 2) {
            $schema->{options}->{$key} = $value;
        }
    }
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
