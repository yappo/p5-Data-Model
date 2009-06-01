package Data::Model::Driver::DBI::MasterSlave;
use strict;
use warnings;
use base 'Data::Model::Driver::DBI';

use Carp ();

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
