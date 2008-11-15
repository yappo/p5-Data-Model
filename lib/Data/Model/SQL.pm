package Data::Model::SQL;
use strict;
use warnings;
use base qw(Data::Model::Accessor);

__PACKAGE__->mk_accessors(qw/ select where having bind limit offset select_map select_map_reverse column_mutator where_values /);


for my $name (qw/ from joins /) {
    no strict 'refs';
    *{$name} = sub {
        return $_[0]->{$name} unless @_ > 1;
        my $self = shift;
        $self->{$name} = ((@_ == 1 && ref($_[0]) eq 'ARRAY') ? $_[0] : [@_]);
    };
}

for my $name (qw/ group order /) {
    no strict 'refs';
    *{$name} = sub {
        return $_[0]->{$name} unless @_ > 1;
        my $self = shift;
        $self->{$name} = ((@_ == 1 && ref($_[0]) eq 'ARRAY') ? $_[0] : [@_]);
    };
}

sub new {
    my($class, %args) = @_;
    my $self = bless { %args }, $class;
    for my $name (qw/ select from joins bind group order where /) {
        unless ($self->$name && ref $self->$name eq 'ARRAY') {
            $self->$name ? $self->$name([ $self->$name ]) : $self->$name([]);;
        }
    }
    for my $name (qw/ select_map select_map_reverse where_values /) {
        $self->$name( {} ) unless $self->$name && ref $self->$name eq 'HASH';
    }

    # ここで select, join, where クエリ 等を%args から構築する

=pod

  Data::Model::SQL->new(
      where => +[
          foo => [ -and => 'foo', 'bar', 'baz'],
          bar => 'baz',
          baz => +{ '!=' => 2 },
      ],
      order => [
          +{ foo => 'ASC' },
      ],
      joins => [
          foo => [
              { inner => { 'baz b1' => 'foo.baz_id = b1.baz_id AND b1.quux_id = 1' }}
          ],
      ],
      group => [qw/ foo bar /],
  );

=cut

    $self;
}

sub add_select {
    my($self, $term, $col) = @_;
    push @{ $self->{select} }, $term;
    return unless $col;
    $self->select_map->{$term}        = $col;
    $self->select_map_reverse->{$col} = $term;
}

sub add_join {
    my($self, $table, $joins) = @_;
    push @{ $self->joins }, {
        table => $table,
        joins => ref($joins) eq 'ARRAY' ? $joins : [ $joins ],
    };
}

sub add_where {
    my($self, $col, $val) = @_;
    ## xxx Need to support old range and transform behaviors.
    Carp::croak("Invalid/unsafe column name $col") unless $col =~ /^[\w\.]+$/ || ref($col) eq 'SCALAR';
    my($term, $bind, $tcol) = $self->_mk_term($col, $val);
    push @{ $self->{where} }, "($term)";
    push @{ $self->{bind} }, @{ $bind };

    $self->where_values->{$tcol} = $val if defined $tcol;
}

sub add_where_sql {
    my($self, $term, @bind) = @_;

    my(@columns, @values);
    while (my($column, $value) = splice @bind, 0, 2) {
        $self->where_values->{$column} = $value;
        push @columns, $column;
        push @values,  $value;
    }

    push @{ $self->{where} }, sprintf("($term)", @columns);
    push @{ $self->{bind} }, @values;
}

sub add_having {
    my $stmt = shift;
    my($col, $val) = @_;

    if (my $orig = $stmt->select_map_reverse->{$col}) {
        $col = $orig;
    }

    my($term, $bind) = $stmt->_mk_term($col, $val);
    push @{ $stmt->{having} }, "($term)";
    push @{ $stmt->{bind} }, @$bind;
}

sub as_select {
    my $self = shift;
    my $sql = '';
    if (@{ $self->select }) {
        $sql .= 'SELECT ';
        $sql .= join(', ',  map {
            my $alias = $self->select_map->{$_};
            $alias ? /(?:^|\.)\Q$alias\E$/ ? $_ : "$_ $alias" : $_;
        } @{ $self->select });
        $sql .= "\n";
    }
    $sql;
}

sub as_join {
    my $self = shift;
    my $sql = '';
    if ($self->joins && @{ $self->joins }) {
        my $initial_table_written = 0;
        for my $data (@{ $self->joins }) {
            my($table, $joins) = map { $data->{$_} } qw( table joins );
            $sql .= $table unless $initial_table_written++;
            for my $join (@{ $joins }) {
                my($type, $target) = (%{ $join });
                my $condition = '';
                if (ref $target eq 'HASH') {
                    my($key, $val) = (%{ $target });
                    $target    = $key;
                    $condition = $val;
                }
                $sql .= ' ' . uc($type) . ' JOIN ' . $target;
                $sql .= ' ON ' . $condition if $condition;
            }
        }
        $sql .= ', ' if @{ $self->from };
    }
    $sql;
}

sub as_sql_where {
    my $self = shift;
    if ($self->where && @{ $self->where }) {
        return 'WHERE ' . join(' AND ', @{ $self->where }) . "\n";
    }
    return '';
}

sub as_sql_having {
    my $self = shift;
    if ($self->having && @{ $self->having }) {
        return 'HAVING ' . join(' AND ', @{ $self->having }) . "\n";
    }
    return '';
}

sub as_limit {
    my $self = shift;
    my $n = $self->limit or return '';
    die "Non-numerics in limit clause ($n)" if $n =~ /\D/;
    return sprintf "LIMIT %d%s\n", $n,
           ($self->offset ? " OFFSET " . int($self->offset) : "");
}

sub as_aggregate {
    my($self, $set) = @_;
    return '' unless my $attribute = $self->$set;

    my @sqls;
    for my $element (@{ $attribute }) {
        my $ref = ref $element;
        if (!$ref) {
            push @sqls, $element;
        } elsif ($ref eq 'HASH') {
            while (my($column, $desc) = each %{ $element }) {
                push @sqls, $column . ' ' . uc($desc);
            }
        }
    }
    return '' unless @sqls;
    return uc($set) . ' BY ' . join(', ', @sqls) . "\n";
}

sub as_sql {
    my $self = shift;

    my $sql = '';
    $sql .= $self->as_select;

    $sql .= 'FROM ';
    ## Add any explicit JOIN statements before the non-joined tables.
    $sql .= $self->as_join;
    $sql .= join(', ', @{ $self->from }) . "\n";

    $sql .= $self->as_sql_where;

    $sql .= $self->as_aggregate('group');
    $sql .= $self->as_sql_having;
    $sql .= $self->as_aggregate('order');

    $sql .= $self->as_limit;
    $sql;
}

sub _mk_term {
    my($self, $col, $val) = @_;
    my $term = '';
    my (@bind, $m);
    if (ref($col) eq 'SCALAR') {
        $term = ${ $col };
        $col  = undef;
    } elsif (ref($val) eq 'ARRAY') {
        if (ref $val->[0] or (($val->[0] || '') eq '-and')) {
            my $logic = 'OR';
            my @values = @$val;
            if ($val->[0] eq '-and') {
                $logic = 'AND';
                shift @values;
            }

            my @terms;
            for my $v (@values) {
                my($term, $bind) = $self->_mk_term($col, $v);
                push @terms, "($term)";
                push @bind, @$bind;
            }
            $term = join " $logic ", @terms;
        } else {
            $col = $m->($col) if $m = $self->column_mutator;
            $term = "$col IN (".join(',', ('?') x scalar @$val).')';
            @bind = @$val;
        }
    } elsif (ref($val) eq 'HASH') {
        $col = $m->($col) if $m = $self->column_mutator;
        my($op, $v) = (%{ $val });
        $term = "$col $op ?";
        push @bind, $v;
    } elsif (ref($val) eq 'SCALAR') {
        $col = $m->($col) if $m = $self->column_mutator;
        $term = "$col $$val";
    } else {
        $col = $m->($col) if $m = $self->column_mutator;
        $term = "$col = ?";
        push @bind, $val;
    }
    ($term, \@bind, $col);
}

1;

__END__

base code L<Data::ObjectDriver::SQL>

