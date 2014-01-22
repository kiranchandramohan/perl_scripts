#!/usr/bin/perl
use Getopt::Long;
use WWW::Mechanize ;

my $csv_url = 'http://129.215.90.114/data/mso_setting4.html' ;
my $acquire_url = "http://129.215.90.114/data/comm.html" ;
my $panda_ip = "129.215.91.125" ;

my %benchmark_data = (
	"doitgen" => [64,1,64],
	"dotproduct" => [4194304,65536,64],
	"edge_detect" => [2048,32,64],
	"floydwarshall" => [512,8,64],
	"histo" => [4096,64,64],
	"matmul" => [1024,16,64],
	"regdetect" => [64,1,64]
) ;

my $benchmark = "" ;
my $data_size = 0 ;
my $block_size = 0 ;
my $range_size = 0 ;

sub set_benchmark_data
{
	$benchmark = $_[0] ;
	($data_size,$block_size,$range_size) = @{$benchmark_data{$benchmark}} ;
        my $output = `ssh $panda_ip /home/kiran/phd_project_$benchmark/test.pl -opti 2>&1` ;
}

sub get_status
{
	if($_[0] eq '200') {
		return "OK" ;
	} else {
		return "ERROR" ;
	}
}

sub get_csv
{
	my $mech = $_[0] ;
	my $channel = 'select:control ch'.$_[1] ;
	my $fname = $_[2].'.csv' ;
	$mech->get($csv_url) ;
	$result = $mech->submit_form(
			form_name => 'firstForm', #name of the form
			fields      =>	{
						command    => "$channel",
					},
			button    => 'wfmsend' #name of the submit button
				    ) ;
	#print $result->content() ;
	#print "Get CSV, status = ", get_status($mech->status), "\n" ;
	open (MYFILE, ">$fname") ;
	print MYFILE $result->content() ;
	close (MYFILE) ; 
}

sub single_acquisition
{
	my $mech = $_[0] ;
	$mech->get($acquire_url) ;
	$result = $mech->submit_form(
			form_name => 'gpresp', #name of the form
			fields      =>	{
						datatimeout	=> '5',
						command		=> ':FPANEL:PRESS SINGLESEQ',
					},
			button    => 'gpibsend' #name of the submit button
				    );
	#print $result->content() ;
	#print "Single Acquisition, status = ", get_status($mech->status), "\n" ;
}

sub get_remote_cmd
{
	$size_a9 = $_[0] ;
	$size_m3 = $_[1] ;
	$size_dsp = $_[2] ;
	$single_proc = $_[3] ;

	if($size_m3 > 0 and $size_dsp > 0) {
		if($size_a9 == 0) {
			return "sudo /home/kiran/phd_project_$benchmark/app -r dsp=$size_dsp,sysm3=$size_m3" ;
		} else {
			return "sudo /home/kiran/phd_project_$benchmark/app -l 2 -r dsp=$size_dsp,sysm3=$size_m3" ;
		}
	} elsif($size_m3 > 0) {
		if(($size_m3 == $data_size) or ($single_proc == 1)) {
			return "sudo /home/kiran/phd_project_$benchmark/app -r sysm3=$size_m3" ;
		} else {
			return "sudo /home/kiran/phd_project_$benchmark/app -l 2 -r sysm3=$size_m3" ;
		}
	} elsif($size_dsp > 0) {
		if(($size_dsp == $data_size) or ($single_proc == 1)) {
			return "sudo /home/kiran/phd_project_$benchmark/app -r dsp=$size_dsp" ;
		} else {
			return "sudo /home/kiran/phd_project_$benchmark/app -l 2 -r dsp=$size_dsp" ;
		}
	} else {
		if($single_proc == 1) {
			my $sub_size = $data_size - $size_a9 ;
			return "sudo /home/kiran/phd_project_$benchmark/app -l 2 -x $sub_size" ;
		} else {
			return "sudo /home/kiran/phd_project_$benchmark/app -l 2" ;
		}
	}
}

my $mech = WWW::Mechanize->new() ;
my $reset_cmd = "sudo /home/kiran/scripts/reset_syslink.sh" ;

sub measure_voltage
{
	my $voltage_pin = $_[0] ;
	my $single_proc = 0 ;
	for(my $i=0 ; $i<=$range_size ; $i+=4) {
		for(my $j=0 ; $j<=$range_size ; $j+=4) {
			my $m3_size = $i * $block_size ;
			my $dsp_size = $j * $block_size ;
			my $k ;
			if($single_proc==1) {
				$k = 0 ;
			} else {
				$k = $range_size - ($i+$j) ;
			}
			my $a9_size = $k*$block_size ;
			if(($a9_size == 0) and ($dsp_size > 0)) {
				#or (($m3_size == 16) and ($dsp_size == 0))) {
				my $remote_cmd = get_remote_cmd($a9_size, $m3_size, $dsp_size,$single_proc) ;
				#my @indices = (1..3) ;
				my @indices = (1) ;
				foreach my $indx (@indices) {
					my $output_file = $benchmark."_".$voltage_pin."_a9-".$k."-m3-".$i."-dsp-".$j."_".$indx ;
					print "$output_file\n" ;
					#system("ssh $panda_ip $reset_cmd") ;
					#sleep(5) ;
					system("ssh $panda_ip $remote_cmd&") ;
					sleep(10) ;
					single_acquisition($mech) ;
					sleep(110) ;
					get_csv($mech,1,$output_file) ;
					sleep(10) ;
				}
			}
		}
	}
}

sub measure_voltage_wrapper
{
	my $proc = $_[0] ;
	set_benchmark_data("doitgen") ;
	measure_voltage($proc) ;
	set_benchmark_data("dotproduct") ;
	measure_voltage($proc) ;
	set_benchmark_data("edge_detect") ;
	measure_voltage($proc) ;
	set_benchmark_data("floydwarshall") ;
	measure_voltage($proc) ;
	set_benchmark_data("histo") ;
	measure_voltage($proc) ;
	set_benchmark_data("regdetect") ;
	measure_voltage($proc) ;
	#set_benchmark_data("matmul") ;
	#measure_voltage($proc) ;
}

#sub measure_voltage
#{
#	my $voltage_pin = $_[0] ;
#	my $single_proc = 1 ;
#	for(my $i=0 ; $i<=0 ; $i+=4) {
#		for(my $j=0 ; $j<=0 ; $j+=4) {
#			for(my $h=0 ; $h<=$range_size ; $h+=4) {
#				my $m3_size = $i * $block_size ;
#				my $dsp_size = $j * $block_size ;
#				my $k = 64 - $h ;
#				my $a9_size = $k*$block_size ;
#				if($a9_size >= 0) {
#					my $remote_cmd = get_remote_cmd($a9_size, $m3_size, $dsp_size,$single_proc) ;
#					my @indices = (1) ;
#					foreach my $indx (@indices) {
#						my $output_file = $voltage_pin."_a9-".$k."-m3-".$i."-dsp-".$j."_".$indx ;
#						print "$output_file\n" ;
#						system("ssh $panda_ip $remote_cmd&") ;
#						sleep(10) ;
#						single_acquisition($mech) ;
#						sleep(210) ;
#						get_csv($mech,1,$output_file) ;
#						sleep(10) ;
#					}
#				}
#			}
#		}
#	}
#}

my $a9 ;
my $m3 ;
my $dsp ;
my $idle ;
GetOptions ("a9"  => \$a9,   # flag
		"m3"  => \$m3,   # flag
		"dsp"  => \$dsp,   # flag
		"idle=s"  => \$idle)   # flag
or die("Error in command line arguments\n");
die "Specify atleast one option : (a9, m3, dsp, idle)" unless ($a9 or $m3 or $dsp or $idle) ;

if($a9) {
	measure_voltage_wrapper("a9") ;
}
if($m3) {
	measure_voltage_wrapper("m3") ;
}
if($dsp) {
	measure_voltage_wrapper("dsp") ;
}
if($idle) {
	my $vpin = $idle ;
	my $output_file = $vpin."_idle_1" ;
	single_acquisition($mech) ;
	sleep(110) ;
	get_csv($mech,1,$output_file) ;
}
