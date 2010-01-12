$ENV{PV_TEST_PERL} = 1;
my $file = $0;
$file =~ s/-pp//;
require "$file";
