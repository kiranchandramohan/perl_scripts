#!/usr/bin/perl
use strict;
use warnings;

my @files = glob("broadcast_ip.txt");
foreach my $file (@files) {
	open (FILE, $file) or die "Cannot open file $file\n" ;
	print "$file\n";
	while(<FILE>) {
		my $line = $_ ;
		chomp($line) ;

		my $ip = $line ;
		#print "$ip\n" ;
		my @lookup_res = `nslookup $ip` ;
		if($lookup_res[3] =~ m/name = ([\S]+)/) {
			print "name : $1\n" ;
		}
	}
	close FILE ;

}

exit 0;
