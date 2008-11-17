package t::Utils;
use strict;
use warnings;
use File::Temp ();
use DBI;
use Path::Class;
use lib Path::Class::Dir->new('t', 'lib')->stringify;

sub import {
    my($class, %args) = @_;
    my $caller = caller;

    strict->import;
    warnings->import;

    for my $name (qw/ temp_filename setup_sqlite /) {
        no strict 'refs';
        *{"$caller\::$name"} = \&{$name};
    }
}

sub temp_filename {
    my $fh = File::Temp->new;
    my $filename = $fh->filename;
    close $fh;
    $filename;
}

sub setup_sqlite {
    my($dsn, @sqls) = @_;
    my $dbh = DBI->connect($dsn,
                           '', '', { RaiseError => 1, PrintError => 0 });
    for my $sql (@sqls) {
        $dbh->do( $sql );
    }
    $dbh->disconnect;
}


1;
