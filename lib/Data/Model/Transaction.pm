package Data::Model::Transaction;
use strict;

use Carp ();
$Carp::Internal{(__PACKAGE__)}++;

sub new {
    my($class, $model) = @_;
    $model->txn_begin;
    bless [ 0, $model, ], $class;
}

sub rollback {
    return if $_[0]->[0];
    $_[0]->[1]->txn_rollback;
    $_[0]->[0] = 1;
}

sub commit {
    return if $_[0]->[0];
    $_[0]->[1]->txn_commit;
    $_[0]->[0] = 1;
}

sub DESTROY {
    my($dismiss, $model) = @{ $_[0] };
    return if $dismiss;

    {
        local $@;
        eval { $model->txn_rollback };
        my $rollback_exception = $@;
        if($rollback_exception) {
            Carp::croak "Rollback failed: ${rollback_exception}";
        }
    }
}

# handle of Data::Model model methods
my @model_methods = qw/
    lookup lookup_multi get get_multi
    set set_multi replace update update_direct
    delete delete_direct delete_multi
/;
for my $method (@model_methods) {
    no strict 'refs';
    *{$method} = sub {
        use strict;
        my $self = shift;

        # check the on transaction
        Carp::croak "You cannot use $method method, Because you leave the transaction scope." if $self->[0];

        # check driver
        my $datamodel = $self->[1];
        my $model = $_[0];
        my $driver;
        if (ref($model) && $model->isa('Data::Model::Row')) {
            my $schema = $datamodel->_get_schema_by_row($model);
            $model  = $schema->model;
            $driver = $schema->driver;
        } else {
            $driver = $datamodel->get_schema($model)->driver;
        }
        unless (($datamodel->get_base_driver)+0 == $driver+0) {
            Carp::croak "'$model' has driver is not same base_driver";
        }

        local $datamodel->{active_transaction} = 0;
        $datamodel->$method(@_);
    };
}

1;

__END__

=head1 NAME

Data::Model::Transaction - transaction manager for Data::Model

=head1 SYNOPSIS

  sub foo {
      my $is_die = shift;
  
      my $model = Your::Model->new;
      my $txn = $model->txn_scope; # start transaction
  
      my $row = $txn->lookup( user => 1 ); # $model->lookup doesn't work.
      $row->name('transaction name');
      $txn->update( $row ); # update
      return if $is_die; # rollback
      if ($is_die) {
          $txn->rollback; # explicitly rollback
          return;
      }

      $txn->commit; # commit
  }

  foo(1); # rollback
  foo(0); # commit

lookup, lookup_multi, get, get_multi, set, replace, set_multi, update, update_direct, delete, delete_direct, delete_multi and txn_scope and txn_begin derived from DataModel are not usable temporarily.

When you use these methods, please carry out via the instance which txn_scope returns.

=head1 SEE ALSO

L<Data::Model>

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo <at> shibuya <döt> plE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
