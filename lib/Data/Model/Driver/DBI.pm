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


sub get {
    my($self, $schema, $key, $columns, %args) = @_;

    $columns = +{} unless $columns;

    $columns->{select} ||= [
        keys %{ $schema->{column} },
    ];

    $columns->{from} ||= [];
    unshift @{ $columns->{from} }, $schema->{model};

    my $stmt = Data::Model::SQL->new(%{ $columns });
    if ($key) { 
        # add where
        my $i = 0;
        for my $i (0..( scalar(@{ $key }) - 1 )) {
            $stmt->add_where( $schema->{key}->[$i] => $key->[$i] );
        }
    }
    my $sql = $stmt->as_sql;

    my @bind;
    my $map = $stmt->select_map;
    my $rec = +{};
    for my $col (@{ $stmt->select }) {
        push @bind, \$rec->{ exists $map->{$col} ? $map->{$col} : $col };
    }

    my $dbh = $self->r_handle;
    $self->start_query($sql, $stmt->bind);
    my $sth = $args{no_cached_prepare} ? $dbh->prepare($sql) : $dbh->prepare_cached($sql);
    $sth->execute(@{ $stmt->bind });
    $sth->bind_columns(undef, @bind);

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
    return $iterator;
}

# insert or replace
sub set {
    my($self, $schema, $key, $columns, %args) = @_;

    my $table = $schema->{model};
    my $cols = [ keys %{ $columns } ];
    my $sql = "INSERT INTO $table\n";
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

    $columns;
}

# update


# delete
sub delete {
    my($self, $schema, $key, $columns, %args) = @_;

    $columns->{from} = [ $schema->{model} ];
    my $stmt = Data::Model::SQL->new(%{ $columns });
    if ($key) { 
        # add where
        my $i = 0;
        for my $i (0..( scalar(@{ $key }) - 1 )) {
            $stmt->add_where( $schema->{key}->[$i] => $key->[$i] );
        }
    }
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
