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

    for my $name (qw/ temp_filename run /) {
        no strict 'refs';
        *{"$caller\::$name"} = \&{$name};
    }

    if ($args{config}) {
        $class->setup_test($caller, $args{config});
    }
}

my $RUN_CODE = sub {};
sub setup_test {
    my($class, $caller, $config) = @_;

    my $test   = "Mock::Tests::$config->{type}";
    my $driver = "Data::Model::Driver::$config->{driver}";
    eval "
    use Mock::Tests::$config->{type};
    use $driver;
    ";
    $@ && die $@;

    my $mock   = "Mock::$config->{type}";
    my $dsn    = $config->{dsn} || '';
    if ($dsn =~ /sqlite/i) {
        my $dbfile = temp_filename();
        $dsn .= $dbfile;
    }

    $main::DRIVER = $driver->new(
        dsn => $dsn,
        username => $config->{username} || '',
        password => $config->{password} || '',
        %{ $config->{driver_config} },
    );
    eval "use $mock"; $@ and die $@;

    if ($dsn =~ /sqlite/i) {
        setup_schema( $dsn => $mock->as_sqls );
    }

    $RUN_CODE = sub {
        my $mock = $mock->new;
        $test->set_mock($mock);
        $test->runtests;
    };
}

sub run {
    $RUN_CODE->();
}

sub temp_filename {
    my $fh = File::Temp->new;
    my $filename = $fh->filename;
    close $fh;
    $filename;
}

sub setup_schema {
    my($dsn, @sqls) = @_;
    my $dbh = DBI->connect($dsn,
                           '', '', { RaiseError => 1, PrintError => 0 });
    for my $sql (@sqls) {
        $dbh->do( $sql );
    }
    $dbh->disconnect;
}


1;
