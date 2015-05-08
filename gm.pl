#!/usr/bin/perl
use strict ;
use warnings ;
use Statistics::Descriptive ;

my %name_to_stat ;
my @type_list ;

sub get_stat
{
  my $name = $_[0] ;
  if(not exists $name_to_stat{$name}) {
    my $stat = Statistics::Descriptive::Full->new();
    $name_to_stat{$name} = $stat ;
    push(@type_list,$name) ;
  }
  return $name_to_stat{$name} ;
}

my $file = "lg" ;
my $fh ;
open($fh,"<",$file) or die "Cannot open file $file" ;
my $line ;
while($line = <$fh>) {
  chomp($line) ;
  if($line =~ m/Running\s+(\S+)/) {
    print "\n$1" ;
  } elsif($line =~ m/Speedup\s+(\S+)\s+=\s+(\S+)/) {
    my $stat = get_stat($1) ;
    $stat->add_data($2) ;
    print " $2" ;
  }
}
close($fh) ;

#foreach my $k (sort {$name_to_stat{$a}->geometric_mean() <=> $name_to_stat{$b}->geometric_mean()} keys %name_to_stat) {
#  print "$k : ".$name_to_stat{$k}->geometric_mean()."\n" ;
#}
print "\navrg" ;
foreach my $k (@type_list) {
  print " ".$name_to_stat{$k}->geometric_mean() ;
}

