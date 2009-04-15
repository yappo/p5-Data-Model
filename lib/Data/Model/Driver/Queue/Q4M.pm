package Data::Model::Driver::Queue::Q4M;
use strict;
use warnings;
use base 'Data::Model::Driver::DBI';

use Carp ();

sub timeout { $_[0]->{timeout} }

sub _create_arguments {
    my $arg_length = scalar(@_);
    my $timeout;
    my %callbacks;
    my @queue_tables;
    for (my $i = 0; $i < $arg_length; $i++) {
        my($table, $value) = ($_[$i], $_[$i + 1]);
        if (ref($value) eq 'CODE') {
            # register callback
            push @queue_tables, $table;
            $callbacks{$table} = $value;

        } elsif ($table eq 'timeout' && $value =~ /\A[0-9]+\z/) {
            # timeout
            $timeout = $value;
        }
        $i++;
    }
    (\@queue_tables, \%callbacks, $timeout);
}

sub queue_wait {
    my($self, $timeout, @tables) = @_;

    my $dbh = $self->r_handle;
    my $sql = sprintf 'SELECT queue_wait(%s)', join(', ', (('?') x (scalar(@tables) + 1)));
    my $sth = $dbh->prepare_cached($sql);

    # bind params
    my $i = 1;
    for my $table (@tables) {
        $sth->bind_param($i++, $table, undef);
    }
    $sth->bind_param($i, $timeout, undef);

    $sth->execute;
    $sth->bind_columns(undef, \my $retcode);

    my $rv = $sth->fetch;
    $sth->finish;
    undef $sth;
    return 0 unless $rv && $retcode;
    return $retcode;
}

sub queue_abort {
    my $self = shift;

    my $dbh = $self->r_handle;
    my $sql = 'SELECT queue_abort()';
    my $sth = $dbh->prepare($sql);
    $sth->execute;
}

sub queue_end {
    my $self = shift;

    my $dbh = $self->r_handle;
    my $sql = 'SELECT queue_end()';
    my $sth = $dbh->prepare($sql);
    $sth->execute;
}

sub queue_running {
    my($self, $c) = (shift, shift);
    my $arg_length = scalar(@_);
    Carp::croak 'illegal parameter' if $arg_length % 2;

    # create table attributes
    my($queue_tables, $callbacks, $timeout) = _create_arguments(@_);
    Carp::croak 'required is callback handler' unless @{ $queue_tables };

    my %schema  = map { $_ => 1 } $c->schema_names;
    for my $table (@{ $queue_tables }) {
        my($name) = split /:/, $table;
        Carp::croak "'$name' is missing model name" unless $schema{$name};
    }

    $timeout ||= $self->timeout || 60;

    # queue_wait
    my $table_id = $self->queue_wait($timeout, @{ $queue_tables });
    return unless $table_id;

    # get record
    my $running_table = $queue_tables->[$table_id - 1];
    my($real_table) = split /:/, $running_table;
    my($row) = $c->get( $real_table );
    unless ($row) {
        $self->queue_abort;
        return;
    }

    # running callback
    eval {
        $callbacks->{$running_table}->($row);
    };
    if ($@) {
        $self->queue_abort;
        die $@; # throwing exception
    }

    $self->queue_end;
    return $real_table;
}

# for schema
sub _as_sql_hook {
    my $self = shift;

    if ($_[1] eq 'get_table_attributes') {
        my $ret = $self->dbd->_as_sql_hook(@_);
        unless ($ret =~ s/(\A|\W)\s*ENGINE\s*=\s*\w+\s*(\z|\W)/${1}TYPE=QUEUE${2}/) {
            $ret ||= 'ENGINE=QUEUE';
        }
        return $ret;
    } else {
        return $self->dbd->_as_sql_hook(@_);
    }
}

1;


__END__


=head1 NAME

Data::Model::Driver::Queue::Q4M - Q4M manager for Data::Model

=head1 SYNOPSIS

  use Data::Model::Driver::Queue::Q4M;
  my $driver = Data::Model::Driver::Queue::Q4M->new(
      dsn      => 'dbi:mysql:database=test',
      username => '',
      password => '',
      timeout  => 60, # queue_wait timeout
  );

  {
    package MyQueue;
    use base 'Data::Model';
    use Data::Model::Mixin modules => ['Queue::Q4M'];
    use Data::Model::Schema;

    base_driver $driver;
    install_model smtp => schema {
        column id
            => char => {};
        column data
            => int => {};
    };

    install_model pop => schema {
        column id
            => char => {};
        column data
            => int => {};
    };
  }

  my $model = MyQueue->new;

  # add queue
  $model->set(
      smtp => {
          id   => 'foo',
          data => 1,
      }
  );

  # same queue_wait('smtp', 'pop', 10);
  my $retval = $model->queue_running(
      smtp => sub {
          my $row = shift;
          is($row->id, 'foo');
          is($row->data, 1);
      },
      pop => sub {
          my $row = shift;
      },
      timeout => 10, # optional
  );

  # same queue_wait('smtp:data>10');
  my $retval = $model->queue_running(
      'smtp:data>10' => sub {
          my $row = shift;
          is($row->id, 'foo');
          is($row->data, 1);
      },
  );

=cut
