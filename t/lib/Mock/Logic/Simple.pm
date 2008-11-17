package Mock::Logic::Simple;
use strict;
use warnings;
use base 'Data::Model';
use Data::Model::Schema;
use Data::Model::Driver::Logic;

my $logic = Data::Model::Driver::Logic->new;

install_model user => schema {
    driver $logic;
    key 'id';
    columns qw/id name/;
};

sub get_user {
    my($self, $schema, $key, $columns, %args) = @_;
    my $obj = +{ id => $key->[0] };
    $obj->{name} = 'Osawa' if $key->[0] eq 'yappo';
    $obj->{name} = 'Danjou' if $key->[0] eq 'lopnor';
    $obj;
}

sub set_user {
    my($self, $schema, $key, $columns, %args) = @_;
    $columns;
}

sub update_user {}

sub delete_user {
    my($self, $schema, $key, $columns, %args) = @_;
    $key->[0] eq 'ok' ? 1 : 0;
}

install_model barerow => schema {
    driver $logic;
    key 'id';
    columns qw/ id name /;
    schema_options bare_row => 1;
};

sub get_barerow { get_user(@_) }
sub set_barerow { set_user(@_) }
sub delete_barerow { delete_user(@_) }

1;
