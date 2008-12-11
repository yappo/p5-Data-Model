package Data::Model::Schema::SQL;
use strict;
use warnings;

sub new {
    my($class, $schema) = @_;
    bless { schema => $schema }, $class;
}

sub call_method {
    my $self   = shift;
    my $method = shift;

    $self->$method(@_) unless $self->{schema}->driver;
    my @ret = $self->{schema}->driver->_as_sql_hook( $self, $method => @_ );
    return @ret if defined $ret[0];
    return $self->$method(@_);
}

sub as_column_type {
    my($self, $column, $args) = @_;
    my $type = uc($args->{type});

    my $size = $args->{options}->{size} || 0;
    $size = 0 unless $size =~ /^\d+$/;
    if ($type =~ m/int/i) {
        $type .= "($size)" if $size;
    } elsif ($type =~ m/(?:real|float|double|numeric|decimal)/i) {
        my $decimals = $args->{options}->{decimals} || 0;
        $decimals = 0 unless $decimals =~ /^\d+$/;
        if ($size && $decimals) {
            $type .= "($size,$decimals)";
        } elsif ($size) {
            $type .= "($size)";
        }
    } elsif ($type =~ m/char/i) {
        $size ||= 255;
        $type .= "($size)";;
    }
    $type;
}

sub as_type_attributes {
    my($self, $column, $args) = @_;
    my $sql;
    $sql .= $args->{options}->{unsigned} ? ' UNSIGNED' : '';
    $sql .= $args->{options}->{zerofill} ? ' ZEROFILL' : '';
    $sql .= $args->{options}->{binary}   ? ' BINARY'   : '';
    $sql .= $args->{options}->{ascii}    ? ' ASCII'    : '';
    $sql .= $args->{options}->{unicode}  ? ' UNICODE'  : '';
    $sql;
}

sub as_default {
    my($self, $column, $args) = @_;
    my $default = $args->{options}->{default};
    if (!defined($default)) {
        return '';
    }
    if (CORE::ref($default) and CORE::ref($default) eq 'CODE') {
        return '';
    }

    if ($args->{type} =~ m/(?:int|real|float|double|numeric|decimal)/i) {
        return ' DEFAULT ' . $default
    }
    return " DEFAULT '" . $default ."'";
}

sub as_column {
    my($self, $column, $args) = @_;

    my $opts = $args->{options};
    return sprintf('%-15s %-15s', $column, $self->call_method( as_column_type => $column, $args ))
        . $self->call_method( as_type_attributes => $column, $args )
        . ($opts->{require} ? ' NOT NULL' : ($opts->{null} ? ' NULL' : ''))
        . $self->call_method( as_default => $column, $args )
        . ($opts->{auto_increment} ? ' AUTO_INCREMENT' : '')
        . ($self->{unique} ? ' UNIQUE' : '')
        . ($self->{primary_key} ? ' PRIMARY KEY' : '')
        . ($self->{references} ? ' REFERENCES '
           . $self->{references}->{table}->{name} .'('
           . $self->{references}->{name} .')' : '')
    ;
}

sub as_primary_key {
    my($self, $key) = @_;
    return () unless @{ $key };
    return 'PRIMARY KEY (' . join(', ', @{ $key }) .')';
}

sub as_unique {
    my($self, $unique) = @_;
    return () unless @{ $unique };

    my @sql = ();
    for my $data (@{ $unique }) {
        my($name, $columns)  = @{ $data };
        push(@sql, 'UNIQUE ' . $name . ' (' . join(', ', @{ $columns }) . ')');
    }
    return @sql;
}

sub as_foreign {
    my $self = shift;
    return () unless @{ $self->{schema}->{foreign} };

    my $sql = '';
    for my $foreign (@{ $self->{schema}->{foreign} }) {
        my @cols = @{ $foreign->{columns} };
        my @refs = @{ $foreign->{references} };
        $sql .= 'FOREIGN KEY ('
                . join(', ', @cols)
                . ') REFERENCES ' . $refs[0]->{table}->{name} .' ('
                . join(', ', @refs)
                . ')'
        ;
    }
    return $sql;
}

sub as_table_attributes {
    my $self = shift;
    return '' unless ref($self->{schema}->options->{create_sql_attributes}) eq 'HASH';
    my($ret) = $self->call_method( 'get_table_attributes', $self->{schema}->options->{create_sql_attributes} );
    $ret ? " $ret" : '';
}
sub get_table_attributes {}

sub as_create_table {
    my $self = shift;
    my $schema = $self->{schema};

    my @values;
    my %columns = %{ $schema->column };
    for my $column ($schema->column_names) {
        push @values, $self->call_method( as_column => $column, $schema->column->{$column} );
    }

    my @key    = @{ $schema->key };
    my $unique_hash = $schema->unique;
    my @unique = sort { $a->[0] cmp $b->[0] }
        map { [ $_ => $unique_hash->{$_} ] }
            keys %{ $unique_hash };

    if (my $name = $schema->options->{key_as_unique}) {
        unshift @unique, [ $name, [ @key ] ];
        @key = ();
    }

    push(@values, $self->call_method( 'as_primary_key', \@key ));
    push(@values, $self->call_method( 'as_unique', \@unique ));
    push(@values, $self->call_method( 'as_foreign' ));

    return 'CREATE TABLE '
           . $self->{schema}->model
           . " (\n    " . join(",\n    ", grep { $_ } @values) . "\n)"
           . $self->as_table_attributes,
    ;
}

sub as_index {
    my $self = shift;
    my @sql = ();

    while (my($name, $columns) = each %{ $self->{schema}->{index} }) {
        push(@sql, 'CREATE'
                . ' INDEX '
                . $name
                . ' ON ' . $self->{schema}->model
                . ' (' . join(',', @{ $columns } ) . ')'
        );
    }
    return @sql;
}

sub as_create_indexes {
    my $self = shift;
    $self->call_method( 'as_index' );
}


sub as_sql {
    my $self = shift;
    return ($self->as_create_table, $self->as_create_indexes);
}


1;

__END__

copied by L<SQL::DB::Schema::Table>, L<SQL::DB::Schema::Column>
