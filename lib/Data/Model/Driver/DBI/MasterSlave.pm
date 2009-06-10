package Data::Model::Driver::DBI::MasterSlave;
use strict;
use warnings;
use base 'Data::Model::Driver::DBI';

use Carp ();
$Carp::Internal{(__PACKAGE__)}++;

sub init {
    my $self = shift;
    my $master = $self->{master}
        or Carp::croak "'master' configuration is required";
    my $slave  = $self->{slave} || $master;

    if (my($type) = $master->{dsn} =~ /^dbi:(\w*)/i) {
        $self->{dbd} = Data::Model::Driver::DBI::DBD->new($type);
    }
    $self->{dbi_config} = +{
        master => +{ %{ $master } },
        slave  => +{ %{ $slave } },
    };
}

sub rw_handle { $_[0]->_get_dbh('master') };
# トランザクション中は master のみを返す
sub r_handle  { $_[0]->_get_dbh( $_[0]->{active_transaction} ? 'master' : 'slave' ) };

1;

=head1 NAME

Data::Model::Driver::DBI::MasterSlave - master-slave composition for mysql

=head1 SYNOPSIS

  package MyDB;
  use base 'Data::Model';
  use Data::Model::Schema;
  use Data::Model::Driver::DBI;
  
  my $dbi_connect_options = {};
  my $driver = Data::Model::Driver::DBI::MasterSlave->new(
      master => {
          dsn => 'dbi:mysql:host=master.server:database=test',
          username => 'master',
          password => 'master',
          connect_options =. $dbi_connect_options,
      },
      slave  => {
          dsn => 'dbi:mysql:host=slave.server:database=test',
          username => 'slave',
          password => 'slave',
          connect_options =. $dbi_connect_options,
      },
  );

  base_driver $driver;
  install_model model_name => schema {
    ....
  };

=head1 DESCRIPTION

It can use with standard master-slave composition.

=head1 SEE ALSO

L<DBI>,
L<Data::Model::Driver::DBI>,
L<Data::Model>

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo <at> shibuya <döt> plE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
