package Data::Model::Schema;
use strict;
use warnings;

use Carp ();
use Encode ();

use Data::Model::Row;
use Data::Model::Schema::Properties;

my  $SUGAR_MAP    = +{};
our $COLUMN_SUGAR = +{};

sub import {
    my($class, %args) = @_;
    my $caller = caller;
    $SUGAR_MAP->{$caller} = $args{sugar} || 'default';
    $COLUMN_SUGAR->{$SUGAR_MAP->{$caller}} ||= +{};

    no strict 'refs';
    for my $name (qw/ base_driver driver install_model schema column columns key index unique schema_options column_sugar
        utf8_column utf8_columns alias_column /) {
        *{"$caller\::$name"} = \&$name;
    }

    my $__properties = +{
        base_driver  => undef,
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
        driver                  => $caller->__properties->{base_driver},
        schema_class            => $caller,
        model                   => $name,
        class                   => $pkg,
        column                  => {},
        columns                 => [],
        index                   => {},
        unique                  => {},
        key                     => [],
        foreign                 => [],
        triggers                => {},
        options                 => {},
        utf8_columns            => {},
        inflate_columns         => [],
        deflate_columns         => [],
        has_inflate             => 0,
        has_deflate             => 0,
        alias_column            => {},
        aluas_column_revers_map => {},
    );

    $caller->__properties->{__process_tmp}->{name} = $name;
    $CALLER = $caller;
    $schema_code->();
    unless ($schema->options->{bare_row}) {
        no strict 'refs';
        @{"$pkg\::ISA"} = ( 'Data::Model::Row' );
        _install_columns_to_class($schema);
        _install_alias_columns_to_class($schema);
    }
    $schema->setup_inflate;
    $CALLER = undef;
    delete $caller->__properties->{__process_tmp};

    if ($schema->driver) {
        $schema->driver->init_model($name, $schema);
    }
}
sub schema (&) { shift }

sub _install_columns_to_class {
    my $schema = shift;
    no strict 'refs';
    while (my($column, $args) = each %{ $schema->column }) {
        my $alias_list = $schema->aluas_column_revers_map->{$column};

        if ($alias_list) {
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
                for my $alias (@{ $alias_list }) {
                    $schema->alias_column->{$alias}->{inflate2alias}->( $obj );
                }
                return $obj->{column_values}->{$column};
            };
        } else {
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
}

sub _install_alias_columns_to_class {
    my $schema = shift;
    no strict 'refs';
    while (my($column, $args) = each %{ $schema->alias_column }) {
        my $base         = $args->{base};
        my $deflate_code = $args->{deflate};
        my $is_utf8      = $args->{is_utf8};
        my $charset      = $args->{charset} || 'utf8';

        if ($is_utf8 && $deflate_code) {
            *{ $schema->class . "::$column" } = sub {
                my $obj = shift;
                # getter
                return $obj->{alias_values}->{$column} unless @_;
                # setter
                $obj->{alias_values}->{$column} = $_[0];
                $obj->$base( Encode::encode($charset, $deflate_code->( $_[0] ) ) );
                return $_[0];
            };
        } elsif ($is_utf8) {
            *{ $schema->class . "::$column" } = sub {
                my $obj = shift;
                # getter
                return $obj->{alias_values}->{$column} unless @_;
                # setter
                $obj->{alias_values}->{$column} = $_[0];
                $obj->$base( Encode::encode($charset, $_[0]) );
                return $_[0];
            };
        } elsif ($deflate_code) {
            *{ $schema->class . "::$column" } = sub {
                my $obj = shift;
                # getter
                return $obj->{alias_values}->{$column} unless @_;
                # setter
                $obj->{alias_values}->{$column} = $_[0];
                $obj->$base( $deflate_code->($_[0]) );
                return $_[0];
            };
        } else {
            *{ $schema->class . "::$column" } = sub {
                my $obj = shift;
                # getter
                return $obj->{alias_values}->{$column} unless @_;
                # setter
                $obj->{alias_values}->{$column} = $_[0];
                $obj->$base( $_[0] );
                return $_[0];
            };
        }
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

sub base_driver ($) {
    my $caller = caller;
    return unless $caller->can('__properties');
    $caller->__properties->{base_driver} = shift;
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
sub utf8_column ($;$;$) {
    my($name, $schema) = _get_model_schema;
    $schema->add_utf8_column(@_);
}
sub utf8_columns (@) {
    my($name, $schema) = _get_model_schema;
    my @columns = @_;
    for my $column (@columns) {
        $schema->add_utf8_column($column);
    }
}

sub alias_column {
    my($name, $schema) = _get_model_schema;
    $schema->add_alias_column(@_);
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


sub column_sugar (@) {
    my($column, $type, $options) = @_;
    Carp::croak "usage: add_column_sugar 'table_name.column_name' => type => { args };"
        unless $column =~ /^[^\.+]+\.[^\.+]+$/;

    my $caller = caller;
    $COLUMN_SUGAR->{$SUGAR_MAP->{$caller}} ||= +{};
    $COLUMN_SUGAR->{$SUGAR_MAP->{$caller}}->{$column} = +{
        type    => $type    || 'char',
        options => $options || +{},
    };
}

sub get_column_sugar {
    my($class, $schema) = @_;
    $COLUMN_SUGAR->{$SUGAR_MAP->{$schema->{schema_class}}};
}

1;

__END__

target table_name => schema {

    column field_name
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

    column field_name_2
        => char => {
            inflate => 'uri',
            deflate => 'uri',
        };
};
