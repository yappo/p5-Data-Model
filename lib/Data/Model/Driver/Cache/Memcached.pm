package Data::Model::Driver::Cache::Memcached;
use strict;
use warnings;
use base 'Data::Model::Driver::Cache';


sub add_to_cache {
    my($self, $key, $data) = @_;

    my $ret = $self->{memcached}->add($key, $data);
    return if !defined $ret;
    return $ret;
}

sub get_from_cache {
    my($self, $key) = @_;

    my $ret = $self->{memcached}->get($key);
    return if !defined $ret;
    return $ret;
}

sub get_multi_from_cache {
    my($self, $keys) = @_;

    my $ret = $self->{memcached}->get_multi($keys);
    return if !defined $ret;
    return $ret;
}

sub remove_from_cache {
    my($self, $key) = @_;
    
    my $ret = $self->{memcached}->delete($key);
    return if !defined $ret;
    return $ret;
}

1;

=head1 NAME

Data::Model::Driver::Cache::Memcached - Penetration cache is offered to the basic driver by memcached protocol

=head1 SYNOPSIS

  package MyDB;
  use base 'Data::Model';
  use Data::Model::Schema;
  use Data::Model::Driver::DBI;
  use Data::Model::Driver::Cache::Memcached;
  
  my $dbi_connect_options = {};
  my $fallback_driver = Data::Model::Driver::DBI->new(
      dsn             => 'dbi:mysql:host=localhost:database=test',
      username        => 'user',
      password        => 'password',
      connect_options => $dbi_connect_options,
  );

  my $driver = Data::Model::Driver::Cache::Memcached->new(
      fallback  => $fallback_driver,
      memcached => Cache::Memcached::Fast->new({ servers => [ { address => "localhost:11211" }, ], }),
  );
  
  base_driver $driver;
  install_model model_name => schema {
    ....
  };

=head1 DESCRIPTION

Penetration cache is offered to the basic driver.
Cash is stored in the memcached protocol server.

When cash does not hit, it asks fallback driver.

=head1 SEE ALSO

L<Cache::Memcached::Fast>,
L<Data::Model>

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo <at> shibuya <döt> plE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
