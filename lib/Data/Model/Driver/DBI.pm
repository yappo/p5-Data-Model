package Data::Model::Driver::DBI;
use strict;
use warnings;
use base 'Data::Model::Driver';

use Carp ();
use DBI;
use Data::Dumper;

use Data::Model::SQL;
use Data::Model::Driver::DBI::DBD;

sub dsn { shift->{dsn} }
sub dbh { shift->{dbh} }
sub dbd { shift->{dbd} }
sub username { shift->{username} }
sub password { shift->{password} }
sub connect_options { shift->{connect_options} }

sub init {
    my $self = shift;
    if (my($type) = $self->{dsn} =~ /^dbi:(\w*)/i) {
        $self->{dbd} = Data::Model::Driver::DBI::DBD->new($type);
    }
    $self->{dsn} = +{
        rw => $self->{dsn},
    };
}

sub init_db {
    my($self, $name) = @_;
    my $dbh = DBI->connect(
        $self->dsn->{$name}, $self->username, $self->password,
        { RaiseError => 1, PrintError => 0, AutoCommit => 1, %{ $self->connect_options || {} } },
    ) or Carp::croak("Connection error: " . $DBI::errstr);
    $self->{__dbh_init_by_driver} = 1;
    $dbh;
}

sub rw_handle {
    my $self = shift;
    $self->{dbh} = undef if $self->{dbh} and !$self->{dbh}->ping;
    unless ($self->{dbh}) {
        if (my $getter = $self->{get_dbh}) {
            $self->{dbh} = $getter->();
        } else {
            $self->{dbh} = $self->init_db('rw') or die $self->last_error;
        }
    }
    $self->{dbh};
}
sub r_handle { shift->rw_handle(@_) }

sub last_error {}

sub add_key_to_where {
    my($self, $stmt, $columns, $key) = @_;
    if ($key) { 
        # add where
        my $i = 0;
        for my $i (0..( scalar(@{ $key }) - 1 )) {
            $stmt->add_where( $columns->[$i] => $key->[$i] );
        }
    }
}

sub add_index_to_where {
    my($self, $schema, $stmt, $index_obj) = @_;
    return unless my($index, $index_key) = (%{ $index_obj });
    $index_key = [ $index_key ] unless ref($index_key) eq 'ARRAY';
    for my $index_type (qw/ unique index /) {
        if (exists $schema->{$index_type}->{$index}) {
            $self->add_key_to_where($stmt, $schema->{$index_type}->{$index}, $index_key);
            last;
        }
    }
}

sub fetch {
    my($self, $rec, $schema, $key, $columns, %args) = @_;

    $columns = +{} unless $columns;

    $columns->{select} ||= [
        keys %{ $schema->{column} },
    ];

    $columns->{from} ||= [];
    unshift @{ $columns->{from} }, $schema->{model};

    my $index_query = delete $columns->{index};
    my $stmt = Data::Model::SQL->new(%{ $columns });
    $self->add_key_to_where($stmt, $schema->{key}, $key) if $key;
    $self->add_index_to_where($schema, $stmt, $index_query) if $index_query;
    my $sql = $stmt->as_sql;

    my @bind;
    my $map = $stmt->select_map;
    for my $col (@{ $stmt->select }) {
        push @bind, \$rec->{ exists $map->{$col} ? $map->{$col} : $col };
    }

    my $dbh = $self->r_handle;
    $self->start_query($sql, $stmt->bind);
    my $sth = $args{no_cached_prepare} ? $dbh->prepare($sql) : $dbh->prepare_cached($sql);
    $sth->execute(@{ $stmt->bind });
    $sth->bind_columns(undef, @bind);

    $sth;
}


sub get {
    my($self, $schema, $key, $columns, %args) = @_;

    my $rec = +{};
    my $sth = $self->fetch($rec, $schema, $key, $columns, %args);

    my $i = 0;
    my $iterator = sub {
        return $rec if $i++ eq 1;
        unless ($sth->fetch) {
            $sth->finish;
            $self->end_query($sth);
            return;
        }
        $rec;
    };

    # pre load
    return unless $iterator->();
    return $iterator, +{
        end => sub { $sth->finish; $self->end_query($sth) },
    };
}

# insert or replace
sub set {
    my $self = shift;
    $self->_insert_or_replace(0, @_);
}

sub replace {
    my($self, $schema, $key, $columns, %args) = @_;
    if ($self->dbd->can_replace) {
        return $self->_insert_or_replace(1, $schema, $key, $columns, %args);
    } else {
#        $self->thx(sub {
        $self->delete($schema, $key, +{}, %args);
        return $self->set($schema, $key, $columns, %args);
#        });
    }
}

sub _insert_or_replace {
    my($self, $is_replace, $schema, $key, $columns, %args) = @_;
    my $select_or_replace = $is_replace ? 'REPLACE' : 'INSERT';

    my $table = $schema->{model};
    my $cols = [ keys %{ $columns } ];
    my $sql = "$select_or_replace INTO $table\n";
    $sql .= '(' . join(', ', @{ $cols }) . ')' . "\n" .
            'VALUES (' . join(', ', ('?') x @{ $cols }) . ')' . "\n";

    my $dbh = $self->rw_handle;
    $self->start_query($sql, $columns);
    my $sth = $dbh->prepare_cached($sql);
    my $i = 1;
    while (my($col, $val) = each %{ $columns }) {
        my $type = $schema->{columns}->{$col}->{type} || 'char';
        my $attr = $self->dbd->bind_param_attributes($type, $columns, $col);
        $sth->bind_param($i++, $val, $attr);
    }
    $sth->execute;
    $sth->finish;
    $self->end_query($sth);

    # set autoincrement key
    if (my @keys = @{ $schema->{key} }) {
        for my $column (@keys) {
            if (exists $schema->{column}->{$column}->{options}->{auto_increment} && 
                    $schema->{column}->{$column}->{options}->{auto_increment}) {
                $columns->{$column} = $self->dbd->fetch_last_id( $schema, $columns, $dbh, $sth );
            }
        }
    }

    $columns;
}

# update
sub update {
    my($self, $schema, $old_key, $key, $old_columns, $columns, $changed_columns, %args) = @_;

    my $stmt = Data::Model::SQL->new;
    $self->add_key_to_where($stmt, $schema->{key}, $old_key);

    my $where_sql = $stmt->as_sql_where;
    return unless $where_sql;

    my @bind;
    my @set;
    for my $column (keys %{ $changed_columns }) {
        push @set, "$column = ?";
        push @bind, $columns->{$column};
    }
    push @bind, @{ $stmt->bind };

    my $sql = 'UPDATE ' . $schema->{model} . ' SET ' . join(', ', @set) . ' ' . $where_sql;
    my $dbh = $self->rw_handle;
    $self->start_query($sql, \@bind);
    my $sth = $dbh->prepare_cached($sql);
    $sth->execute(@bind);
    $sth->finish;
    $self->end_query($sth);

    return $sth->rows;
}

# delete
sub delete {
    my($self, $schema, $key, $columns, %args) = @_;

    $columns->{from} = [ $schema->{model} ];
    my $index_query = delete $columns->{index};
    my $stmt = Data::Model::SQL->new(%{ $columns });
    $self->add_key_to_where($stmt, $schema->{key}, $key) if $key;
    $self->add_index_to_where($schema, $stmt, $index_query) if $index_query;

    my $sql = "DELETE " . $stmt->as_sql;
    my $dbh = $self->rw_handle;
    $self->start_query($sql, $stmt->bind);
    my $sth = $dbh->prepare_cached($sql);
    $sth->execute(@{ $stmt->bind });
    $sth->finish;
    $self->end_query($sth);

    return $sth->rows;
}


# profile
sub start_query {}
sub end_query {}

sub DESTROY {
    my $self = shift;
    return unless $self->{__dbh_init_by_driver};

#    if (my $dbh = $self->dbh) {
#        $dbh->disconnect if $dbh;
#    }
}


1;
