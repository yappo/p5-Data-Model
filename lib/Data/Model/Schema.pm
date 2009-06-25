package Data::Model::Schema;
use strict;
use warnings;

use Carp ();
$Carp::Internal{(__PACKAGE__)}++;
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

    unless ($args{skip_import}) {
        no strict 'refs';
        for my $name (qw/ base_driver driver install_model schema column columns key index unique schema_options column_sugar
                          utf8_column utf8_columns alias_column add_method /) {
            *{"$caller\::$name"} = \&$name;
        }
    }

    my $__properties = +{
        base_driver  => undef,
        schema       => +{},
        __process_tmp => +{
            class => $caller,
        },
    };

    no strict 'refs';
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
        _build_tmp              => {},
    );

    $caller->__properties->{__process_tmp}->{name} = $name;
    $CALLER = $caller;
    $schema_code->();
    $schema->setup_inflate;
    unless ($schema->options->{bare_row}) {
        no strict 'refs';
        @{"$pkg\::ISA"} = ( 'Data::Model::Row' );
        _install_columns_to_class($schema);
        _install_alias_columns_to_class($schema);
    }
    $CALLER = undef;
    delete $caller->__properties->{__process_tmp};

    if ($schema->driver) {
        $schema->driver->attach_model($name, $schema);
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
                    delete $obj->{alias_values}->{$alias};
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
        my $base          = $args->{base};
        my $deflate_code  = $args->{deflate};
        my $is_utf8       = $args->{is_utf8};
        my $charset       = $args->{charset} || 'utf8';
        my $inflate2alias = $args->{inflate2alias};

        if ($is_utf8 && $deflate_code) {
            *{ $schema->class . "::$column" } = sub {
                my $obj = shift;
                # getter
                return $obj->{alias_values}->{$column} ||= $inflate2alias->($obj) unless @_;
                # setter
                $obj->{alias_values}->{$column} = $_[0];
                $obj->$base( Encode::encode($charset, $deflate_code->( $_[0] ) ) );
                return $_[0];
            };
        } elsif ($is_utf8) {
            *{ $schema->class . "::$column" } = sub {
                my $obj = shift;
                # getter
                return $obj->{alias_values}->{$column} ||= $inflate2alias->($obj) unless @_;
                # setter
                $obj->{alias_values}->{$column} = $_[0];
                $obj->$base( Encode::encode($charset, $_[0]) );
                return $_[0];
            };
        } elsif ($deflate_code) {
            *{ $schema->class . "::$column" } = sub {
                my $obj = shift;
                # getter
                return $obj->{alias_values}->{$column} ||= $inflate2alias->($obj) unless @_;
                # setter
                $obj->{alias_values}->{$column} = $_[0];
                $obj->$base( $deflate_code->($_[0]) );
                return $_[0];
            };
        } else {
            *{ $schema->class . "::$column" } = sub {
                my $obj = shift;
                # getter
                return $obj->{alias_values}->{$column} ||= $inflate2alias->($obj) unless @_;
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

sub add_method {
    my($name, $schema) = _get_model_schema;
    my($method, $code) = @_;
    no strict 'refs';
    *{$schema->class."::$method"} = $code;
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

=head1 NAME

Data::Model::Schema - Schema DSL for Data::Model

=head1 SYNOPSIS

  package Your::Model;
  use base 'Data::Model';
  use Data::Model::Schema;
  use Data::Model::Driver::DBI;
  
  my $dbfile = '/foo/bar.db';
  my $driver = Data::Model::Driver::DBI->new(
      dsn => "dbi:SQLite:dbname=$dbfile",
  );
  base_driver( $driver ); # set the storage driver for Your::Model


  install_model tweet => schema { # CREATE TABLE tweet (
    key 'id'; # primary key
    index index_name [qw/ user_id at /]; # index index_name(user_id, at);

    column id
        => int => {
            auto_increment => 1,
            required       => 1,
            unsigned       => 1,
        }; # id   UNSIGNED INT NOT NULL AUTO_INCREMENT,

    column user_id
        => int => {
            required       => 1,
            unsigned       => 1,
        }; # user_id   UNSIGNED INT NOT NULL,

    column at
        => int => {
            required       => 1,
            default        => sub { time() },
            unsigned       => 1,
        }; # at   UNSIGNED INT NOT NULL, # If it is empty at the time of insert   time() is used.

    utf8_column body # append to auto utf8 inflating
        => varchar => {
            required       => 1,
            size           => 140,
            default        => '-',
        }; # body   VARCHAR(140) NOT NULL DEFAULT'-',


    column field_name
        => char => {
            default    => 'aaa', # default value
            auto_increment => 1, # auto_increment
            inflate => sub { unpack("H*", $_[0]) }, # inflating by original function
            deflate => sub { pack("H*", $_[0]) },   # deflating by original function
        };

    column field_name_2
        => char => {
            inflate => 'URI', # use URI inflate see L<Data::Model::Schema::Inflate>
            deflate => 'URI', # use URI deflate see L<Data::Model::Schema::Inflate>
        };

    columns qw/ foo bar /; # create columns uses default config
};

=head1 GLOBAL DSL

=head2 install_model, schema

  model name and it schema is set up.

  install_model model_name schema {
  };

=head2 base_driver

set driver ( Data::Model::Driver::* ) for current package's default.


=head2 column_sugar

column_sugar promotes reuse of a schema definition.

see head1 COLUMN SUGAR

=head1 SCHEMA DSL

=head2 driver

driver used only in install_model of current.

  install_model local_driver => schema {
      my $driver = Data::Mode::Driver::DBI->new( dsn => 'DBI:SQLite:' );
      driver($driver);
   }

=head2 column

It is a column definition.

  column column_name => column_type => \%options;

column_name puts in the column name of SQL schema.

column_type puts in the column type of SQL schema. ( INT CHAR BLOB ... )

=head2 columns

some columns are set up. However, options cannot be set.

=head2 utf8_column

column with utf8 inflated.

=head2 utf8_columns

columns with utf8 inflated.

=head2 alias_column

alias is attached to a specific column.

It is helpful. I can use, when leaving original data and inflateing.

    { package Name; use Moose; has 'name' => ( is => 'rw' ); }
    # in schema 
    columns qw( name nickname );
    alias_column name     => 'name_name';
    alias_column nickname => 'nickname_name'
        => {
            inflate => sub {
                my $value = shift;
                Name->new( name => $value );
            }

    # in your script
    is $row->nickname, $row->nickname_name->name;

=head2 key

set the primary key.
Unless it specifies key, it does not move by lookup and lookup_multi.

  key 'id';
  key [qw/ id sub_id /]; # multiple key

=head2 index

  index 'name'; # index name(name);
  index name => [qw/ name name2 /]; # index name(name, name2)

=head2 unique

  unique 'name'; # unique name(name);
  unique name => [qw/ name name2 /]; # unique name(name, name2)

=head2 add_method

A method is added to Row class which install_model created.

  add_method show_name => sub {
      my $row = shift;
      printf "Show %s\n", $row->name;
  };
  
  $row->name('yappo');
  $row->show_name; # print "Show yappo\n"

=head2 schema_options

some option to schema is added.

It is used when using InnoDB in MySQL.

  schema_options create_sql_attributes => {
      mysql => 'TYPE=InnoDB',
  };

=head1 COLUMN OPTIONS

The option which can be used in a column definition.

Pasted the definition of ParamsValidate. It writes later.

=head2 size

                size   => {
                    type     => SCALAR,
                    regex    => qr/\A[0-9]+\z/,
                    optional => 1,
                },

=head2 required

                required   => {
                    type     => BOOLEAN,
                    optional => 1,
                },

=head2 null

                null       => {
                    type     => BOOLEAN,
                    optional => 1,
                },

=head2 signed

                signed     => {
                    type     => BOOLEAN,
                    optional => 1,
                },

=head2 unsigned

                unsigned   => {
                    type     => BOOLEAN,
                    optional => 1,
                },

=head2 decimals

                decimals   => {
                    type     => BOOLEAN,
                    optional => 1,
                },

=head2 zerofill

                zerofill   => {
                    type     => BOOLEAN,
                    optional => 1,
                },

=head2 binary

                binary     => {
                    type     => BOOLEAN,
                    optional => 1,
                },

=head2 ascii

                ascii      => {
                    type     => BOOLEAN,
                    optional => 1,
                },

=head2 unicode

                unicode    => {
                    type     => BOOLEAN,
                    optional => 1,
                },

=head2 default

                default    => {
                    type     => SCALAR | CODEREF,
                    optional => 1,
                },

=head2 auto_increment

                auto_increment => {
                    type     => BOOLEAN,
                    optional => 1,
                },

=head2 inflate

                inflate => {
                    type     => SCALAR | CODEREF,
                    optional => 1,
                },

=head2 deflate

                deflate => {
                    type     => SCALAR | CODEREF,
                    optional => 1,
                },


=head1 COLUMN SUGAR

UNDOCUMENTED

  package Mock::ColumnSugar;
  use strict;
  use warnings;
  use base 'Data::Model';
  use Data::Model::Schema sugar => 'column_sugar';
  
  column_sugar 'author.id'
      => 'int' => +{
          unsigned => 1,
          required => 1, # we can used to require or required
      };
  column_sugar 'author.name'
      => 'varchar' => +{
          size    => 128,
          require => 1,
      };
  
  column_sugar 'book.id'
      => 'int' => +{
          unsigned => 1,
          require  => 1,
      };
  column_sugar 'book.title'
      => 'varchar' => +{
          size    => 255,
          require => 1,
      };
  column_sugar 'book.description'
      => 'text' => +{
          require => 1,
          default => 'not yet writing'
      };
  column_sugar 'book.recommend'
      => 'text';
  
  
  install_model author => schema {
      driver $main::DRIVER;
      key 'id';
  
      column 'author.id' => { auto_increment => 1 }; # column name is id
      column 'author.name'; # column name is name
  };
  
  install_model book => schema {
      driver $main::DRIVER;
      key 'id';
      index 'author_id';
  
      column 'book.id'   => { auto_increment => 1 }; # column name is id
      column 'author.id'; # column name is author_id
      column 'author.id' => 'sub_author_id' => { required => 0 }; # column name is sub_author_id
      column 'book.title'; # column name is title
      column 'book.description'; # column name is description
      column 'book.recommend'; # column name is recommend
  };

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo <at> shibuya <döt> plE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

