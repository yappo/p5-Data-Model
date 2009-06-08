package Data::Model::Schema::Properties;
use strict;
use warnings;
use base qw(Data::Model::Accessor);

use Carp ();
$Carp::Internal{(__PACKAGE__)}++;

use Class::Trigger qw( pre_insert pre_save post_save post_load pre_update pre_inflate post_inflate pre_deflate post_deflate );
use Encode ();
use Params::Validate ':all';

use Data::Model::Schema;
use Data::Model::Schema::Inflate;
use Data::Model::Schema::SQL;

__PACKAGE__->mk_accessors(qw/ driver schema_class model class column index unique key options has_inflate has_deflate alias_column aluas_column_revers_map /);


our @RESERVED = qw(
    update save new
    add_trigger call_trigger remove_trigger
);


sub new {
    my($class, %args) = @_;
    bless { %args }, $class;
}

sub new_obj {
    my $self = shift;
    $self->{class}->new(@_);
}

sub has_index {
    $_[0]->{unique}->{$_[1]} || $_[0]->{index}->{$_[1]}
}

sub add_keys {
    my($self, $key, %args) = @_;
    $self->{key} = ref($key) eq 'ARRAY' ? $key : [ $key ];
}

BEGIN {
    for my $name (qw/ unique index /) {
        no strict 'refs';
        *{"add_$name"} = sub {
            my($self, $index, $columns, %args) = @_;
            my $key = $columns || $index;
            die sprintf '%s::%s : %s name is require', $self->schema_class, $self->name, $name
                if ref($index) || !defined $index; 
            $key = [ $key ] unless ref($key) eq 'ARRAY';
            $self->{$name}->{$index} = $key;
        };
    }
}

sub add_column {
    my $self = shift;
    my($column, $type, $options) = @_;
    return $self->add_column_sugar(@_) if $column =~ /^[^\.+]+\.[^\.+]+$/;
    Carp::croak "Column can't be called '$column': reserved name" 
            if grep { lc $_ eq lc $column } @RESERVED;

    Carp::croak 'The multiplex definition of "require" and the "required" is carried out.'
            if exists $options->{require} && exists $options->{required};
    if (exists $options->{require}) {
        $options->{required} = delete $options->{require};
    }

    # validation for $options
    if ($Data::Model::RUN_VALIDATION) {
        my @p = %{ $options };
        validate(
            @p, {
                size   => {
                    type     => SCALAR,
                    regex    => qr/\A[0-9]+\z/,
                    optional => 1,
                },
                required   => {
                    type     => BOOLEAN,
                    optional => 1,
                },
                null       => {
                    type     => BOOLEAN,
                    optional => 1,
                },
                signed     => {
                    type     => BOOLEAN,
                    optional => 1,
                },
                unsigned   => {
                    type     => BOOLEAN,
                    optional => 1,
                },
                decimals   => {
                    type     => BOOLEAN,
                    optional => 1,
                },
                zerofill   => {
                    type     => BOOLEAN,
                    optional => 1,
                },
                binary     => {
                    type     => BOOLEAN,
                    optional => 1,
                },
                ascii      => {
                    type     => BOOLEAN,
                    optional => 1,
                },
                unicode    => {
                    type     => BOOLEAN,
                    optional => 1,
                },
                default    => {
                    type     => SCALAR | CODEREF,
                    optional => 1,
                },
                # validation => {},
                auto_increment => {
                    type     => BOOLEAN,
                    optional => 1,
                },
                inflate => {
                    type     => SCALAR | CODEREF,
                    optional => 1,
                },
                deflate => {
                    type     => SCALAR | CODEREF,
                    optional => 1,
                },
            }
        );
    }

    $self->{utf8_columns}->{$column} = 1
        if delete $self->{_build_tmp}->{utf8_column}->{$column};

    push @{ $self->{columns} }, $column;
    $self->{column}->{$column} = +{
        type    => $type    || 'char',
        options => $options || +{},
    };
}
sub add_utf8_column {
    my $self = shift;
    my($column) = @_;

    $self->{_build_tmp}->{utf8_column} ||= {};
    $self->{_build_tmp}->{utf8_column}->{$column} = 1;
    $self->add_column(@_);
}

sub add_alias_column {
    my $self = shift;
    my($base_name, $alias_name, $args) = @_;
    $self->{aluas_column_revers_map}->{$base_name} ||= [];
    push @{ $self->{aluas_column_revers_map}->{$base_name} }, $alias_name;
    $self->{alias_column}->{$alias_name} = +{
        %{ $args || {} },
        base    => $base_name,
    };
}

sub add_column_sugar {
    my $self   = shift;
    my $name   = shift;
    my $sugar = Data::Model::Schema->get_column_sugar($self);
    Carp::croak "Undefined column of '$name'" 
        unless exists $sugar->{$name} && $sugar->{$name};

    my $conf = $sugar->{$name};
    my %clone = (
        type    => $conf->{type},
        options => +{ %{ $conf->{options} } },
    );
    my $column;
    if (@_ == 0 || ref($_[0])) {
        my $model;
        ($model, $column) = split /\./, $name;
        unless ($self->{model} eq $model) {
            $column = join '_', $model, $column;
        }
    } else {
        $column = shift;
    }
    if (@_ && ref($_[0]) eq 'HASH') {
        $clone{options} = +{ %{ $clone{options} }, %{ ( shift ) } } 
    }
    if (my $alias_args = delete $clone{options}->{alias}) {
        my $rename_map = delete $clone{options}->{alias_rename} || {};
        while (my($alias_name, $args) = each %{ $alias_args }) {
            $self->add_alias_column($column, $rename_map->{$alias_name} || $alias_name, $args);
        }
    }

    $self->{utf8_columns}->{$column} = 1
        if delete $self->{_build_tmp}->{utf8_column}->{$name};

    $self->add_column($column, $clone{type}, $clone{options});
}

sub add_options {
    my $self = shift;
    if (ref($_[0]) eq 'HASH') {
        $self->{options} = shift;
    } elsif (!(@_ % 2)) {
        while (my($key, $value) = splice @_, 0, 2) {
            $self->{options}->{$key} = $value;
        }
    }
}

sub column_names {
    my $self = shift;
    @{ $self->{columns} };
}

sub column_type {
    my($self, $column) = @_;
    return 'char' unless $column && $self->{column}->{$column} && $self->{column}->{$column}->{type};
    $self->{column}->{$column}->{type};
}
sub column_options {
    my($self, $column) = @_;
    $self->{column}->{$column}->{options} || +{};
}

sub setup_inflate {
    my $self = shift;

    $self->{inflate_columns} = [];
    $self->{deflate_columns} = [];

    while (my($column, $data) = each %{ $self->{column} }) {
        my $opts = $data->{options};

        my $inflate = $opts->{inflate};
        if ($inflate && ref($inflate) ne 'CODE') {
            $opts->{inflate} = Data::Model::Schema::Inflate->get_inflate($inflate);
            $opts->{deflate} = $inflate;
            $inflate = $opts->{inflate};
        }
        if (ref($inflate) eq 'CODE') {
            push @{ $self->{inflate_columns} }, $column;
            $self->{has_inflate} = 1;
        } else {
            delete $opts->{inflate};
        }

        my $deflate = $opts->{deflate};
        if ($deflate && ref($deflate) ne 'CODE') {
            $opts->{deflate} = Data::Model::Schema::Inflate->get_deflate($deflate);
            $deflate = $opts->{deflate};
        }
        if (ref($deflate) eq 'CODE') {
            push @{ $self->{deflate_columns} }, $column;
            $self->{has_deflate} = 1;
        } else {
            delete $opts->{deflate};
        }
    }

    if (scalar(%{ $self->{utf8_columns} })) {
        $self->{has_inflate} = $self->{has_deflate} = 1;
        my @columns = keys %{ $self->{column} };
        $self->{inflate_columns} = \@columns;
        $self->{deflate_columns} = \@columns;
    }

    # for alias
    while (my($base, $list) = each %{ $self->{aluas_column_revers_map} }) {
        for my $alias (@{ $list }) {
            my $args    = $self->{alias_column}->{$alias};
            my $inflate = $args->{inflate};

            if ($inflate && ref($inflate) ne 'CODE') {
                $args->{inflate} = Data::Model::Schema::Inflate->get_inflate($inflate);
                $args->{deflate} = Data::Model::Schema::Inflate->get_deflate($inflate);
            }

            my $inflate_code = $args->{inflate};
            my $is_utf8      = $args->{is_utf8};
            my $charset      = $args->{charset} || 'utf8';

            # make inflate2alias
            my $code;

            if ($is_utf8 && $inflate_code) {
                $code = sub {
                    $_[0]->{alias_values}->{$alias} = $inflate_code->( Encode::decode( $charset, $_[0]->{column_values}->{$base} ) );
                };
            } elsif ($is_utf8) {
                $code = sub {
                    $_[0]->{alias_values}->{$alias} = Encode::decode( $charset, $_[0]->{column_values}->{$base} );
                };
            } elsif ($inflate_code) {
                $code = sub {
                    $_[0]->{alias_values}->{$alias} = $inflate_code->( $_[0]->{column_values}->{$base} );
                };
            } else {
                $code = sub {
                    $_[0]->{alias_values}->{$alias} = $_[0]->{column_values}->{$base};
                };
            }
            $args->{inflate2alias} = $code;
        }
    }
}

sub inflate {
    if  ($_[0]->{has_inflate}) {
        my($self, $columns) = @_;
        my $orig_columns;
        if (ref($columns) eq $self->{class}) {
            $orig_columns = $columns;
            $columns = $columns->{column_values};
        } elsif (ref($columns) ne 'HASH') {
            Carp::croak "required types 'HASH' or '$self->{class}' of inflate";
        }
        $self->call_trigger('pre_inflate', $columns, $orig_columns);

        for my $column (@{ $self->{inflate_columns} }) {
            next unless defined $columns->{$column};

            my $opts = $self->{column}->{$column}->{options};
            my $val = $columns->{$column};

            if ($self->{utf8_columns}->{$column}) {
                my $charset = $opts->{charset} || 'utf8';
                $val = Encode::decode($charset, $val);
            }

            $val = $opts->{inflate}->($val) if ref($opts->{inflate}) eq 'CODE';

            $orig_columns->{original_cols}->{$column} ||= $orig_columns->{column_values}->{$column}
                if $orig_columns && $columns->{$column} ne $val;

            $columns->{$column} = $val;
        }
        $self->call_trigger('post_inflate', $columns, $orig_columns);
    }
}

sub deflate {
    return unless $_[0]->{has_deflate};
    my($self, $columns) = @_;
    my $orig_columns;
    if (ref($columns) eq $self->{class}) {
        $orig_columns = $columns;
        $columns = $columns->{column_values};
    } elsif (ref($columns) ne 'HASH') {
        Carp::croak "required types 'HASH' or '$self->{class}' of inflate";
    }
    $self->call_trigger('pre_deflate', $columns, $orig_columns);

    for my $column (@{ $self->{deflate_columns} }) {
        next unless defined $columns->{$column};

        my $opts = $self->{column}->{$column}->{options};
        my $val = $columns->{$column};
        $val = $opts->{deflate}->($val) if ref($opts->{deflate}) eq 'CODE';

        if ($self->{utf8_columns}->{$column}) {
            my $charset = $opts->{charset} || 'utf8';
            $val = Encode::encode($charset, $val);
        }
        $columns->{$column} = $val;
    }
    $self->call_trigger('post_deflate', $columns, $orig_columns);
}

sub set_default {
    my($self, $columns) = @_;

    while (my($name, $conf) = each %{ $self->{column} }) {
        next if exists $columns->{$name};
        next unless exists $conf->{options};
        next unless exists $conf->{options}->{default};

        my $default = $conf->{options}->{default};
        if (ref($default) eq 'CODE') {
            $columns->{$name} = $default->($self, $columns);
        } else {
            $columns->{$name} = $default;
        }
    }
}

sub get_key_array_by_hash {
    my($self, $hash, $index) = @_;

    my $key;
    $key = $self->{unique}->{$index} || $self->{index}->{$index} if $index;
    $key ||= $self->{key};
    $key = [ $key ] unless ref($key) eq 'ARRAY';

    my @keys;
    for my $key (@{ $key }) {
        last unless defined $hash->{$key};
        push @keys, $hash->{$key};
    }
    \@keys;
}

sub get_columns_hash_by_key_array_and_hash {
    my($self, $hash, $array, $index) = @_;
    my $ret = {};

    # by column
    for my $column (keys %{ $self->{column} }) {
        next unless exists $hash->{$column};
        $ret->{$column} = $hash->{$column};
    }

    # by key
    my $key;
    $key = $self->{unique}->{$index} || $self->{index}->{$index} || die "Cannot find index '$index'" if $index;
    $key ||= $self->{key};
    $key = [ $key ] unless ref($key) eq 'ARRAY';

    @{ $ret }{@{ $key }} = @{ $array };
    $ret;
}


sub sql {
    my $self = shift;
    $self->{sql} ||= Data::Model::Schema::SQL->new($self);
}


1;
