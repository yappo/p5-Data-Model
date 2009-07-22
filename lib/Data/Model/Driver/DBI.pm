package Data::Model::Driver::DBI;
use strict;
use warnings;
use base 'Data::Model::Driver';

use Carp ();
$Carp::Internal{(__PACKAGE__)}++;
use DBI;

use Data::Model::SQL;
use Data::Model::Driver::DBI::DBD;

sub dbd { $_[0]->{dbd} }

sub dbi_config {
    my($self, $name) = @_;
    $self->{dbi_config}->{$name}
        or Carp::croak "has not dbi_config name '$name'";
}

sub init {
    my $self = shift;
    if (my($type) = $self->{dsn} =~ /^dbi:(\w*)/i) {
        $self->{dbd} = Data::Model::Driver::DBI::DBD->new($type);
    }
    $self->{dbi_config} = +{
        rw => +{
            dsn             => delete $self->{dsn},
            username        => delete $self->{username},
            password        => delete $self->{password},
            connect_options => delete $self->{connect_options},
            dbh             => undef,
        },
    };
}

my %reuse_handles;
sub init_db {
    my($self, $name) = @_;
    my $dbi_config = $self->dbi_config($name);
    my $dsn = $dbi_config->{dsn};
    my $dbh;
    if ($self->{reuse_dbh}) {
        $dbh = $reuse_handles{$dsn};
    }
    unless ($dbh) {
        $dbh = DBI->connect(
            $dsn, $dbi_config->{username}, $dbi_config->{password},
            { RaiseError => 1, PrintError => 0, AutoCommit => 1, %{ $dbi_config->{connect_options} || {} } },
        ) or Carp::croak("Connection error: " . $DBI::errstr);
        if ($self->{reuse_dbh}) {
            $reuse_handles{$dsn} = $dbh;
        }
    }
    $self->{__dbh_init_by_driver} = 1;
    $dbh;
}

sub _get_dbh {
    my $self = shift;
    my $name = shift || 'rw';
    my %args = @_;
    my $dbi_config = $self->dbi_config($name);
    unless ($args{no_ping}) {
        $dbi_config->{dbh} = undef if $dbi_config->{dbh} and !$dbi_config->{dbh}->ping;
    }
    unless ($dbi_config->{dbh} || $args{isnt_reconnect}) {
        if (my $getter = $self->{get_dbh}) {
            $dbi_config->{dbh} = $getter->();
        } else {
            $dbi_config->{dbh} = $self->init_db($name) or Carp::croak $self->last_error;
        }
    }
    $dbi_config->{dbh};
}

sub rw_handle { shift->_get_dbh('rw', @_) };
sub r_handle  { shift->rw_handle(@_) }

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
        if (exists $schema->$index_type->{$index}) {
            $self->add_key_to_where($stmt, $schema->$index_type->{$index}, $index_key);
            last;
        }
    }
}

sub bind_params {
    my($self, $schema, $columns, $sth) = @_;
    my $i = 1;
    for my $column (@{ $columns }) {
        my($col, $val) = @{ $column };
        my $type = $schema->column_type($col);
        my $attr = $self->dbd->bind_param_attributes($type, $columns, $col);
        $sth->bind_param($i++, $val, $attr || undef);
    }
}

sub fetch {
    my($self, $rec, $schema, $key, $columns, %args) = @_;

    $columns = +{} unless $columns;

    $columns->{select} ||= [ $schema->column_names ];
    $columns->{from}   ||= [];
    unshift @{ $columns->{from} }, $schema->model;

    my $index_query = delete $columns->{index};
    my $stmt = Data::Model::SQL->new(%{ $columns });
    $self->add_key_to_where($stmt, $schema->key, $key) if $key;
    $self->add_index_to_where($schema, $stmt, $index_query) if $index_query;
    my $sql = $stmt->as_sql;

    # bind_params
    my @params;
    for my $i (1..scalar(@{ $stmt->bind })) {
        push @params, [ $stmt->bind_column->[$i - 1], $stmt->bind->[$i - 1] ];
    }

    my @bind;
    my $map = $stmt->select_map;
    for my $col (@{ $stmt->select }) {
        push @bind, \$rec->{ exists $map->{$col} ? $map->{$col} : $col };
    }

    my $sth;
    eval {
        my $dbh = $self->r_handle;
        $self->start_query($sql, $stmt->bind);
        $sth = $args{no_cached_prepare} ? $dbh->prepare($sql) : $dbh->prepare_cached($sql);
        $self->bind_params($schema, \@params, $sth);
        $sth->execute;
        $sth->bind_columns(undef, @bind);
    };
    if ($@) {
        $self->_stack_trace($sth, $sql, $stmt->bind, $@);
    }
    $sth;
}

sub lookup {
    my($self, $schema, $id, %args) = @_;

    my $rec = +{};
    my $sth = $self->fetch($rec, $schema, $id, {}, %args);

    my $rv = $sth->fetch;
    $sth->finish;
    $self->end_query($sth);
    undef $sth;
    return unless $rv;
    return $rec;
}

sub lookup_multi {
    my($self, $schema, $ids, %args) = @_;

    my @keys = @{ $schema->key };
    my $query = {};
    if (@keys == 1) {
        my @id_list = map { $_->[0] } @{ $ids };
        $query = { where => [ $keys[0] => \@id_list ] };
    } else {
        my @queries;
        for my $id (@{ $ids }) {
            my %query;
            @query{@keys} = @{ $id };
            push @queries, '-and' => [ %query ];
        }
        $query = { where => [ -or => \@queries ] };
    }

    my $rec = +{};
    local $args{no_cached_prepare} = 1;
    my $sth = $self->fetch($rec, $schema, undef, $query, %args);

    my %resultlist;
    while ($sth->fetch) {
        my $key = $schema->get_key_array_by_hash($rec);
        $resultlist{join "\0", @{ $key }} = +{ %{ $rec } };
    }

    $sth->finish;
    $self->end_query($sth);
    undef $sth;

    \%resultlist;
}

sub get {
    my($self, $schema, $key, $columns, %args) = @_;

    my $rec = +{};
    my $sth = $self->fetch($rec, $schema, $key, $columns, %args);

    my $i = 0;
    my $iterator = sub {
        return unless $sth;
        return $rec if $i++ eq 1;
        unless ($sth->fetch) {
            $sth->finish;
            $self->end_query($sth);
            undef $sth;
            return;
        }
        $rec;
    };

    # pre load
    return unless $iterator->();
    return $iterator, +{
        end => sub { if ($sth) { $sth->finish; $self->end_query($sth); undef $sth; } },
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

    my $table = $schema->model;
    my $cols = [ keys %{ $columns } ];
    my @column_list = map {
        [ $_ => $columns->{$_} ]
    } @{ $cols };
    my $sql = "$select_or_replace INTO $table\n";
    $sql .= '(' . join(', ', @{ $cols }) . ')' . "\n" .
            'VALUES (' . join(', ', ('?') x @{ $cols }) . ')' . "\n";

    my $sth;
    eval {
        my $dbh = $self->rw_handle;
        $self->start_query($sql, $columns);
        $sth = $dbh->prepare_cached($sql);
        $self->bind_params($schema, \@column_list, $sth);
        $sth->execute;
        $sth->finish;
        $self->end_query($sth);

        # set autoincrement key
        $self->_set_auto_increment($schema, $columns, sub { $self->dbd->fetch_last_id( $schema, $columns, $dbh, $sth ) });
    };
    if ($@) {
        $self->_stack_trace($sth, $sql, \@column_list, $@);
    }

    undef $sth;
    $columns;
}

# update
sub _update {
    my($self, $schema, $changed_columns, $columns, $where_sql, $pre_bind, $pre_bind_column) = @_;

    my @bind;
    my @bind_column;
    my @set;
    for my $column (keys %{ $changed_columns }) {
        my $val = $columns->{$column};
        if (ref($val) eq 'SCALAR') {
            push @set, "$column = " . ${ $val };
        } elsif (!ref($val)) {
            push @set, "$column = ?";
            push @bind, $val;
            push @bind_column, $column;
        } else {
            Carp::confess 'No references other than a SCALAR reference can use a update column';
        }
    }
    push @bind, @{ $pre_bind };
    push @bind_column, @{ $pre_bind_column };

    # bind_params
    my @params;
    for my $i (1..scalar(@bind)) {
        push @params, [ $bind_column[$i - 1], $bind[$i - 1] ];
    }

    my $sql = 'UPDATE ' . $schema->model . ' SET ' . join(', ', @set) . ' ' . $where_sql;
    my $sth;
    eval {
        my $dbh = $self->rw_handle;
        $self->start_query($sql, \@bind);
        $sth = $dbh->prepare_cached($sql);
        $self->bind_params($schema, \@params, $sth);
        $sth->execute;
        $sth->finish;
        $self->end_query($sth);
    };
    if ($@) {
        $self->_stack_trace($sth, $sql, \@params, $@);
    }

    if (wantarray) {
        my @ret = $sth->rows;
        undef $sth;
        return @ret;
    } else {
        my $ret = $sth->rows;
        undef $sth;
        return $ret;
    }
}

sub update {
    my($self, $schema, $old_key, $key, $old_columns, $columns, $changed_columns, %args) = @_;

    my $stmt = Data::Model::SQL->new;
    $self->add_key_to_where($stmt, $schema->key, $old_key);

    my $where_sql = $stmt->as_sql_where;
    return unless $where_sql;

    return $self->_update($schema, $changed_columns, $columns, $where_sql, $stmt->bind, $stmt->bind_column);
}

sub update_direct {
    my($self, $schema, $key, $query, $columns, %args) = @_;

    my $index_query = delete $query->{index};
    my $stmt = Data::Model::SQL->new(%{ $query });
    $self->add_key_to_where($stmt, $schema->key, $key) if $key;
    $self->add_index_to_where($schema, $stmt, $index_query) if $index_query;

    my $where_sql = $stmt->as_sql_where;
    return unless $where_sql;

    return $self->_update($schema, $columns, $columns, $where_sql, $stmt->bind, $stmt->bind_column);
}

# delete
sub delete {
    my($self, $schema, $key, $columns, %args) = @_;

    $columns->{from} = [ $schema->model ];
    my $index_query = delete $columns->{index};
    my $stmt = Data::Model::SQL->new(%{ $columns });
    $self->add_key_to_where($stmt, $schema->key, $key) if $key;
    $self->add_index_to_where($schema, $stmt, $index_query) if $index_query;

    # bind_params
    my @params;
    for my $i (1..scalar(@{ $stmt->bind })) {
        push @params, [ $stmt->bind_column->[$i - 1], $stmt->bind->[$i - 1] ];
    }

    my $sql = "DELETE " . $stmt->as_sql;
    my $sth;
    eval {
        my $dbh = $self->rw_handle;
        $self->start_query($sql, $stmt->bind);
        $sth = $dbh->prepare_cached($sql);
        $self->bind_params($schema, \@params, $sth);
        $sth->execute;
        $sth->finish;
        $self->end_query($sth);
    };
    if ($@) {
        $self->_stack_trace($sth, $sql, $stmt->bind, $@);
    }

    if (wantarray) {
        my @ret = $sth->rows;
        undef $sth;
        return @ret;
    } else {
        my $ret = $sth->rows;
        undef $sth;
        return $ret;
    }
}

# for schema
sub _as_sql_hook {
    my $self = shift;
    $self->dbd->_as_sql_hook(@_);
}

# stack trace
sub _stack_trace {
    my($self, $sth, $sql, $binds, $reason) = @_;
    require Data::Dumper;

    if ($sth) {
        # finalize sth handle
        $sth->finish;
        $self->end_query($sth);
    }

    $sql =~ s/\n/\n          /gm;
    Carp::croak sprintf <<"TRACE", $reason, $sql, Data::Dumper::Dumper($binds);
    **** { Data::Model::Driver::DBI 's Exception ****
Reasone : %s
SQL     : %s
    **** BINDS DUMP ****
%s
    **** Data::Model::Driver::DBI 's Exception } ****
TRACE
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

# for transactions
sub txn_begin {
    my $self = shift;
    $self->{active_transaction} = 1;
    my $dbh = $self->rw_handle;
    eval { $dbh->begin_work } or Carp::croak $@;
}

sub txn_rollback {
    my $self = shift;
    return unless $self->{active_transaction};
    my $dbh = $self->rw_handle;
    eval { $dbh->rollback } or Carp::croak $@;
}

sub txn_commit {
    my $self = shift;
    return unless $self->{active_transaction};
    my $dbh = $self->rw_handle;
    eval { $dbh->commit } or Carp::croak $@;
}

sub txn_end {
    $_[0]->{active_transaction} = 0;
}

1;

=head1 NAME

Data::Model::Driver::DBI - storage driver for DBI

=head1 SYNOPSIS

  package MyDB;
  use base 'Data::Model';
  use Data::Model::Schema;
  use Data::Model::Driver::DBI;
  
  my $dbi_connect_options = {};
  my $driver = Data::Model::Driver::DBI->new(
      dsn             => 'dbi:mysql:host=localhost:database=test',
      username        => 'user',
      password        => 'password',
      connect_options => $dbi_connect_options,
      reuse_dbh       => 1, # sharing dbh (optional)
                            # When you use by MySQL, please set up
                            # connect_options => { mysql_auto_reconnect => 1 },
                            # simultaneously.
  );
  
  base_driver $driver;
  install_model model_name => schema {
    ....
  };

=head1 DESCRIPTION

DBD that is working now is only mysql and SQLite.

=head1 SEE ALSO

L<DBI>,
L<Data::Model>

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo <at> shibuya <döt> plE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
