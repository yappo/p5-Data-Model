package Data::Model::Driver::Cache::HASH;
use strict;
use warnings;
use base 'Data::Model::Driver::Cache';

my %CACHE;

sub add_to_cache {
    my($self, $key, $data) = @_;

    my $ret = $CACHE{$key} = $data;
    return if !defined $ret;
    return $ret;
}

sub get_from_cache {
    my($self, $key) = @_;

    my $ret = $CACHE{$key};
    return if !defined $ret;
    return $ret;
}

sub remove_from_cache {
    my($self, $key) = @_;
    
    my $ret = delete $CACHE{$key};
    return if !defined $ret;
    return $ret;
}

1;

=head1 NAME

Data::Model::Driver::Cache::HASH - Penetration cache is offered to the basic driver

=head1 SYNOPSIS

  package MyDB;
  use base 'Data::Model';
  use Data::Model::Mixin modules => ['Queue::Q4M'];
  use Data::Model::Schema;
  use Data::Model::Driver::DBI;
  use Data::Model::Driver::Cache::HASH;
  
  my $dbi_connect_options = {};
  my $fallback_driver = Data::Model::Driver::DBI->new(
      dsn             => 'dbi:mysql:host=localhost:database=test',
      username        => 'user',
      password        => 'password',
      connect_options =. $dbi_connect_options,
  );

  my $driver = Data::Model::Driver::Cache::HASH->new(
      fallback => $fallback_driver,
  );
  
  base_driver $driver;
  install_model model_name => schema {
    ....
  };

=head1 DESCRIPTION

Penetration cache is offered to the basic driver.
Cash is stored in the standard hash for Perl.

When cash does not hit, it asks fallback driver.

=head1 SEE ALSO

L<Data::Model>

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo <at> shibuya <döt> plE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
