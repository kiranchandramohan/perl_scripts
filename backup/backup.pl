#!/usr/bin/perl
use Getopt::Long;


my $panda ;
my $smpbios ;
my $upload ;
GetOptions ("panda"  => \$panda,   # flag
		"smpbios"  => \$smpbios,   # flag
		"upload=s"  => \$upload)   # flag
or die("Error in command line arguments\n");

die "Specify atleast one option : (panda, smpbios, upload)" unless ($panda or $smpbios or $upload) ;

my $user_name = "export USER=kiran" ;
my $path = "export PATH=/home/kiran/perl5/bin:/home/kiran/CodeSourcery/Sourcery_CodeBench_for_ARM_GNU_Linux/bin:/home/kiran/bin:/usr/lib/lightdm/lightdm:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/home/kiran/llvm/build/Debug+Asserts/bin" ;
my $ssh_agent_pid = "export SSH_AGENT_PID=14447" ;
my $ssh_auth_sock = "export SSH_AUTH_SOCK=/tmp/keyring-EZt1Dy/ssh" ;
my $perl_mm_opt = "export PERL_MM_OPT=INSTALL_BASE=/home/kiran/perl5" ;
my $perl5lib = "export PERL5LIB=/home/kiran/perl5/lib/perl5:" ;
my $perl_mb_opt = "export \"PERL_MB_OPT=--install_base /home/kiran/perl5\"" ;
my $perl_local_lib_root = "export PERL_LOCAL_LIB_ROOT=:/home/kiran/perl5" ;
my $tms470_path = "export TMS470CGTOOLPATH=/opt/ti/ccsv5/tools/compiler/tms470" ;
my $c6000_path = "export C6000CGTOOLPATH=/opt/ti/ccsv5/tools/compiler/c6000" ;
my $bios_path = "export BIOSTOOLSROOT=/opt/ti" ;
my $xdc_version = "export XDCVERSION=xdctools_3_24_02_30" ;
my $bios_version = "export BIOSVERSION=bios_6_34_01_14" ;
my $ipc_version = "export IPCVERSION=ipc_1_24_03_32" ;

my $ssh_vars = $ssh_agent_pid." ; ".$ssh_auth_sock ;
my $perl_vars = $perl_mm_opt. " ; ".$perl5lib. " ; ".$perl_mb_opt. " ; ".$perl_local_lib_root ;
my $bios_vars = $tms470_path." ; ".$c6000_path." ; ".$bios_path." ; ".$xdc_version." ; ".$bios_version." ; ".$ipc_version ;
my $env_vars = $user_name." ; ".$ssh_vars." ; ".$path." ; ".$perl_vars." ; ".$bios_vars ;

my $panda_ip = "129.215.91.125" ;
my $date = `date +"%a_%d-%b-%y_%H-%M-%S"` ;
chomp $date ;
my $local_home = $ENV{'HOME'} ;
my $backup_file_name = "backup_".$date ;
my $backup_directory = $local_home."/backup/current_backup" ;
my $cur_backup_directory = $backup_directory."/".$backup_file_name ;
my $backup_file = $backup_file_name.".tgz" ;
my $gdrive_dir = "/PhD_backups" ;
my $remote_upload_script = $local_home."/"."backup"."/"."net-google-drive-simple/eg/google-drive-upsync \-v" ;

#print "env_vars = $env_vars\n" ;
#print "$env_vars $remote_upload_script $backup_directory $gdrive_dir\n" ;

my @panda_files = (
		"common",
		"phd_project",
		"phd_project_doitgen",
		"phd_project_dotproduct",
		"phd_project_edge_detect",
		"phd_project_floydwarshall",
		"phd_project_histo",
		"phd_project_matmul",
		"phd_project_regdetect",
		"phd_project_simple",
		"my_modules",
		"scripts"
    		) ;

my @local_files = (
		"Downloads/smpbios/common",
		"Downloads/smpbios/sysbios-rpmsg",
		"Downloads/smpbios/sysbios-rpmsg_doitgen",
		"Downloads/smpbios/sysbios-rpmsg_dotproduct",
		"Downloads/smpbios/sysbios-rpmsg_edgedetect",
		"Downloads/smpbios/sysbios-rpmsg_floydwarshall",
		"Downloads/smpbios/sysbios-rpmsg_histo",
		"Downloads/smpbios/sysbios-rpmsg_imgkernel",
		"Downloads/smpbios/sysbios-rpmsg_matmul",
		"Downloads/smpbios/sysbios-rpmsg_multiply",
		"Downloads/smpbios/sysbios-rpmsg_multiply_sum",
		"Downloads/smpbios/sysbios-rpmsg_pathfinder",
		"Downloads/smpbios/sysbios-rpmsg_regdetect",
		"Downloads/smpbios/sysbios-rpmsg_sum"
		) ;

system("rm \-rf $backup_directory\/\*") ;
`mkdir $cur_backup_directory` ;

if($panda) {
	foreach my $fi (@panda_files) {
		my $remote_file = $panda_ip.":".$fi ;
		system("$env_vars ; ssh $panda_ip \" if \[ \-d \"$fi\" \]\; then cd $fi \&\& make clean \; fi\"") ;
		system("$env_vars ; scp -r $remote_file $cur_backup_directory") ;
	}
}

if($smpbios) {
	foreach my $fi (@local_files) {
		my $l_fi = $ENV{'HOME'}."/".$fi ;
		system("$env_vars ; cd $l_fi ; make clean ; cd \- ; cp -r $l_fi $cur_backup_directory") ;
	}
}

system("cd $backup_directory ; tar cvzf $backup_file $backup_file_name && rm -rf $cur_backup_directory ; cd ..") ;
if($upload eq "gdrive") {
	system("$env_vars ; $remote_upload_script $backup_directory $gdrive_dir") ;
} else {
	print "Currently uploading to $gdrive is not supported\n" ;
}

