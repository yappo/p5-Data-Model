package Data::Model::Schema::Properties;
use strict;
use warnings;
use base qw(Data::Model::Accessor);

use Class::Trigger qw( pre_insert pre_save post_save post_load pre_update pre_inflate post_inflate pre_deflate post_deflate );
use Encode ();

use Data::Model::Schema;
use Data::Model::Schema::SQL;

__PACKAGE__->mk_accessors(qw/ driver schema_class model class column index unique key options has_inflate has_deflate /);


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

    push @{ $self->{columns} }, $column;
    $self->{column}->{$column} = +{
        type    => $type    || 'char',
        options => $options || +{},
    };
}
sub add_utf8_column {
    my $self = shift;
    my($name) = @_;
    $self->{utf8_columns}->{$name} = 1;
    $self->add_column(@_);
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
    $self->{column}->{$column}->{type} || 'char';
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
            push @{ $self->{inflate_columns} }, $column;
        }
        $self->{has_inflate} = 1 if $opts->{inflate};

        my $deflate = $opts->{deflate};
        if ($deflate && ref($deflate) ne 'CODE') {
            $opts->{deflate} = Data::Model::Schema::Inflate->get_deflate($deflate);
            push @{ $self->{deflate_columns} }, $column;
        }
        $self->{has_deflate} = 1 if $opts->{deflate};
    }

    if (scalar(%{ $self->{utf8_columns} })) {
        $self->{has_inflate} = $self->{has_deflate} = 1;
        my @columns = keys %{ $self->{column} };
        $self->{inflate_columns} = \@columns;
        $self->{deflate_columns} = \@columns;
    }
}

sub inflate {
    return unless $_[0]->{has_inflate};
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
