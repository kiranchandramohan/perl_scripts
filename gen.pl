#!/usr/bin/perl
use strict ;
use warnings ;
use Cwd;
use Statistics::Descriptive ;

my %level_configs ;
my %config_runtime ;
my %config_power ;
my @freq_list = (1080000,800000,600000,300000) ;

my $pwd = cwd() ;
my @path_comp = split('/',$pwd) ;

use constant UNIT_PARTITION => 4 ;
use constant A9_MAX => 64 ;
use constant MAX_VAL => 2147483647 ;
use constant NO_CONFIG => "NO_CONFIG" ;

use constant NUM_LEVEL_7 => 7 ;

use constant POWER_CPU_ONLY => 101 ;
use constant POWER_ALL_LEVEL => 102 ;
use constant POWER_7_LEVEL => 103 ;
use constant POWER_7_LEVEL_BMARK_AVG => 104 ;
use constant POWER_7_LEVEL_GLOBAL_AVG => 105 ;

use constant PART_BEST => 201 ;
use constant PART_THROUGHPUT => 202 ;
use constant PART_AVERAGE => 203 ;

use constant VALID_POWER_CONFIG => 301 ;
use constant VALID_OR_INVALID_POWER_CONFIG => 301 ;

use constant ALL_LEVEL => 401 ;
use constant _7_LEVEL => 402 ;
use constant CPU_ONLY_LEVEL => 403 ;

use constant MEM_SCALE_FACTOR => 0.75 ;

use constant DEFAULT_PARTITION_MODE => 1001 ;
use constant PRECEDENCE_TO_FASTEST_PROCESSOR => 1002 ;

my $partition_mode = PRECEDENCE_TO_FASTEST_PROCESSOR ;

sub get_distance
{
  my ($a91,$m31,$dsp1) = @{$_[0]} ;
  my ($a92,$m32,$dsp2) = @{$_[1]} ;
  #print "get_distance : $a91-$a92, $m31-$m32, $dsp1-$dsp2\n" ;
  return (sqrt(($a91-$a92)**2+($m31-$m32)**2+($dsp1-$dsp2)**2)) ;
}

sub process_power_file
{
  my $freq = $_[0] ;
  my $file = "raw_data_".$freq ;
  my $fh ;
  my $line ;

  open($fh, "<", $file) ;
  while($line = <$fh>) {
    chomp($line) ;
    if($line =~ m/a9-(\S+)-m3-(\S+)-dsp-(\S+)\s*:\s*(\S+)\s+:\s+(\S+)/) {
      my $config = $freq."_".$1."-".$2."-".$3 ;
      $config_power{$config} = $5 ;
    }
  }
  close($fh) ;
}

sub process_runtime_file
{
  my $freq = $_[0] ;
  my $file = "run_log_".$freq ;
  my $fh ;
  my $line ;
  open($fh, "<", $file) ;
  while($line = <$fh>) {
    chomp($line) ;
    if($line=~ m/A9=(\S+),M3=(\S+),DSP=(\S+)\s+Time<total,runtime,\s+a9-sync,a9,m3,dsp>\s+=\s+<\S+,(\S+),\S+,\S+,\S+,\S+>/) {
      my $config = $freq."_".$1."-".$2."-".$3 ;
      $config_runtime{$config} = $4 ;
    }
  }
  close($fh) ;
}

#This function used to get configs at lower level only
sub get_config_at_level
{
  my $config = $_[0] ;
  my $level = $_[1] ;

  my $cur_config_vals ;
  if($config =~ m/\S+_(\S+)/) {
    $cur_config_vals = $1 ;
  }

  my $lower_config ;
  if($level == 6) {
    $lower_config = "1080000_".$cur_config_vals ;
  } elsif($level == 5) {
    $lower_config = "800000_".$cur_config_vals ;
  } elsif($level == 4) {
    $lower_config = "600000_".$cur_config_vals ;
  } elsif($level == 3) {
    $lower_config = "300000_".$cur_config_vals ;
  } elsif($level == 2) {
    $lower_config = NO_CONFIG ;
  } elsif($level == 1) {
    $lower_config = NO_CONFIG ;
  } elsif($level == 0) {
    $lower_config = NO_CONFIG ;
  } else {
    die "get_config_at_level : invalid level=$level\n" ;
  }
}

sub get_runtime_at_lower_level
{
  my $level = $_[0] ;
  my $power = $_[1] ;
  my $config = $_[2] ;

  #print "get_runtime_at_lower_level : (c=$config,p=$config_power{$config}) -> " ;

  my $cur_runtime = $config_runtime{$config} ;

  my $min_runtime = MAX_VAL ;
  for(my $l=$level-1 ; $l>=0 ; $l--) {
    my $config = get_config_at_level($config,$l) ;
    if($config eq NO_CONFIG) {
      #print "$config\n" ;
      last ;
    } else {
      if($config_power{$config} <= $power) {
        $min_runtime = $config_runtime{$config} ;
        #print "($config,$config_power{$config}) : Lower : $level->$l : $cur_runtime -> $min_runtime\n" ;
        last ;
      }
    }
  }
  return $min_runtime ;
}

sub partition
{
  my $a9_time = $_[0] ;
  my $m3_time = $_[1] ;
  my $dsp_time = $_[2] ;
  my $size = A9_MAX ;

  if($a9_time > 0) {
    my $m3_relative_a9 = $a9_time/$m3_time ;
    my $dsp_relative_a9 = $a9_time/$dsp_time ;
    my $a9_partition = $size/(1+$m3_relative_a9+$dsp_relative_a9) ;
    my $m3_partition = $m3_relative_a9 * $a9_partition ;
    my $dsp_partition = $dsp_relative_a9 * $a9_partition ;
    return($a9_partition,$m3_partition,$dsp_partition) ;
  } else {
    my $m3_speed = 1/$m3_time ;
    my $dsp_speed = 1/$dsp_time ;
    my $a9_partition = 0 ;
    my $m3_partition = ($m3_speed/($m3_speed+$dsp_speed))*$size ;
    my $dsp_partition = ($dsp_speed/($m3_speed+$dsp_speed))*$size ;
    return($a9_partition,$m3_partition,$dsp_partition) ;
  }
}

sub closest_multiple
{
  my $val = $_[0] ;
  my $factor = $_[1] ;
  my $max_val = $_[2] ;

  my $rval = sprintf("%.0f",$val) ;

  my $lower = (int($rval/$factor))*$factor ;
  my $upper = ((int($rval/$factor))+1)*$factor ;

  return ($lower,$upper) ;
}

sub custom_cmp
{
  my ($a,$b,@config) = @_ ;
  #print "custom_cmp : @{$a} @{$b} : @config\n" ;
  my $dist1 = get_distance($a,\@config) ;
  my $dist2 = get_distance($b,\@config) ;  
  return ($dist1 <=> $dist2) ;
}

sub find_closest_configs
{
  my $a9_part = $_[0] ;
  my $m3_part = $_[1] ;
  my $dsp_part = $_[2] ;

  my @zero_arr = (0,0) ;
  my ($a91,$a92) = ($a9_part==0) ? @zero_arr : closest_multiple($a9_part,4,A9_MAX) ;
  my ($m31,$m32) = closest_multiple($m3_part,4,A9_MAX) ;
  my ($dsp1,$dsp2) = closest_multiple($dsp_part,4,A9_MAX) ;
  #print "find_closest_configs : $a91-$a92,$m31-$m32,$dsp1-$dsp2\n" ;


  sub push_config
  {
    if($_[1]+$_[2]+$_[3] == A9_MAX) {
      push(@{$_[0]},[$_[1],$_[2],$_[3]]) ;
    }
  }
  my @configs ;
  push_config (\@configs, $a91,$m32,$dsp1) ;
  push_config (\@configs, $a91,$m32,$dsp1) ;
  push_config (\@configs, $a91,$m32,$dsp2) ;
  push_config (\@configs, $a91,$m32,$dsp2) ;
  push_config (\@configs, $a92,$m31,$dsp1) ;
  push_config (\@configs, $a92,$m31,$dsp1) ;
  push_config (\@configs, $a92,$m31,$dsp2) ;
  push_config (\@configs, $a92,$m31,$dsp2) ;
  push_config (\@configs, $a92,$m32,$dsp1) ;
  push_config (\@configs, $a92,$m32,$dsp2) ;

  my @config = ($a9_part,$m3_part,$dsp_part) ;
  my @sorted_configs = sort {custom_cmp($a,$b,@config)} @configs ;
  #print "sorted_configs = ".scalar(@sorted_configs)."\n" ;

  return @sorted_configs ;
}

sub get_config_throughput_partitioning_helper
{
  my $level = $_[0] ;



  sub get_configs_freq
  {
    my $freq = $_[0] ;
    my $level = $_[1] ;
    my $a9 = $_[2] ;
    my $m3 = $_[3] ;
    my $dsp = $_[4] ;
    my $a9_runtime = $_[5] ;
    my $m3_runtime = $_[6] ;
    my $dsp_runtime = $_[7] ;
 

    sub get_modified_partition_configs
    {
      my $config_ref = $_[0] ;
      my $m_level = $_[1] ;
      my $a9_runtime = $_[2] ;
      my $m3_runtime = $_[3] ;
      my $dsp_runtime = $_[4] ;

      if(($path_comp[5] eq "matmul") or ($path_comp[5] eq "doitgen") or ($partition_mode == DEFAULT_PARTITION_MODE)) {
        return $config_ref ;
      }

      my @new_configs ;
      if($partition_mode == PRECEDENCE_TO_FASTEST_PROCESSOR) {
        foreach my $c (@{$config_ref}) {
          my $a9_partition ;
          my $m3_partition ;
          my $dsp_partition ;
          if($c =~ m/(\S+)_(\S+)-(\S+)-(\S+)/) {
            if($m_level >= 3) {
              if(($dsp_runtime > $m3_runtime) and ($dsp_runtime - $m3_runtime < 0.3)) {
                $a9_partition = $2 + 2*UNIT_PARTITION ;
                $m3_partition = $3 - UNIT_PARTITION ;
                $dsp_partition = $4 - UNIT_PARTITION ;
              } else {
                $a9_partition = $2 + UNIT_PARTITION ;
                if($dsp_runtime >= $m3_runtime and ($4>4)) {
                  $m3_partition = $3 ;
                  $dsp_partition = $4 - UNIT_PARTITION ;
                } else {
                  $m3_partition = $3 - UNIT_PARTITION ;
                  $dsp_partition = $4 ;
                }
              }
              if(($a9_partition < A9_MAX and $m3_partition >0 and $dsp_partition >0)) {
                my $cfg = "$1"."_"."$a9_partition"."-"."$m3_partition"."-"."$dsp_partition" ;
                push(@new_configs,$cfg) ;
              } else {
                push(@new_configs,$c) ;
              }
            } elsif($m_level == 2) {
              $a9_partition = $2 ;
              my $cond = 0 ;
              if($dsp_runtime >= $m3_runtime and ($4>4)) {
                $m3_partition = $3 + UNIT_PARTITION ;
                $dsp_partition = $4 - UNIT_PARTITION ;
                $cond = ($m3_partition < A9_MAX and $dsp_partition >0) ;
              } else {
                $m3_partition = $3 - UNIT_PARTITION ;
                $dsp_partition = $4 + UNIT_PARTITION ;
                $cond = ($dsp_partition < A9_MAX and $m3_partition >0) ;
              }
              if($cond) {
                my $cfg = "$1"."_"."$a9_partition"."-"."$m3_partition"."-"."$dsp_partition" ;
                push(@new_configs,$cfg) ;
              } else {
                push(@new_configs,$c) ;
              }
            } else {
              push(@new_configs,$c) ;
            }
          } else {
            die "get_modified_partition_configs : Invalid config $c" ;
          }
          return \@new_configs ;
        }
      } else {
        die "get_modified_partition_configs : Invalid partition mode $partition_mode" ;
      }
    }


    my @configs ;
    foreach my $c (find_closest_configs($a9,$m3,$dsp)) {
      my ($a9_partition,$m3_partition,$dsp_partition) = @{$c} ;
      my $cfg = "$freq"."_"."$a9_partition"."-"."$m3_partition"."-"."$dsp_partition" ;
      push(@configs, $cfg) ;
      #print "get_configs_freq : level $level : config=$cfg\n" ;
    } 

    my $config_ref= get_modified_partition_configs(\@configs,$level,$a9_runtime,$m3_runtime,$dsp_runtime) ;
    return @{$config_ref} ;
  }

  my $config = NO_CONFIG ;
  if($level == 6) {
    my $a9_runtime = $config_runtime{"1080000_"."64-0-0"} ;
    my $m3_runtime = $config_runtime{"1080000_"."0-64-0"} ;
    my $dsp_runtime = $config_runtime{"1080000_"."0-0-64"} ;
    my ($a9,$m3,$dsp) = partition($a9_runtime,$m3_runtime,$dsp_runtime) ;
    return get_configs_freq(1080000,$level,$a9,$m3,$dsp,$a9_runtime,$m3_runtime,$dsp_runtime) ;
    #print "level 6 : a9=$a9,m3=$m3,dsp=$dsp\n" ;
  } elsif($level == 5) {
    my $a9_runtime = $config_runtime{"800000_"."64-0-0"} ;
    my $m3_runtime = $config_runtime{"800000_"."0-64-0"} ;
    my $dsp_runtime = $config_runtime{"800000_"."0-0-64"} ;
    my ($a9,$m3,$dsp) = partition($a9_runtime,$m3_runtime,$dsp_runtime) ;
    return get_configs_freq(800000,$level,$a9,$m3,$dsp,$a9_runtime,$m3_runtime,$dsp_runtime) ;
  } elsif($level == 4) {
    my $a9_runtime = $config_runtime{"600000_"."64-0-0"} ;
    my $m3_runtime = $config_runtime{"600000_"."0-64-0"} ;
    my $dsp_runtime = $config_runtime{"600000_"."0-0-64"} ;
    my ($a9,$m3,$dsp) = partition($a9_runtime,$m3_runtime,$dsp_runtime) ;
    return get_configs_freq(600000,$level,$a9,$m3,$dsp,$a9_runtime,$m3_runtime,$dsp_runtime) ;
  } elsif($level == 3) {
    my $a9_runtime = $config_runtime{"300000_"."64-0-0"} ;
    my $m3_runtime = $config_runtime{"300000_"."0-64-0"} ;
    my $dsp_runtime = $config_runtime{"300000_"."0-0-64"} ;
    my ($a9,$m3,$dsp) = partition($a9_runtime,$m3_runtime,$dsp_runtime) ;
    return get_configs_freq(300000,$level,$a9,$m3,$dsp,$a9_runtime,$m3_runtime,$dsp_runtime) ;
  } elsif($level == 2) {
    my $a9_runtime = 0 ;
    my $freq = "1080000" ;
    my $m3_runtime = $config_runtime{$freq."_"."0-64-0"} ;
    my $dsp_runtime = $config_runtime{$freq."_"."0-0-64"} ;
    my ($a9,$m3,$dsp) = partition($a9_runtime,$m3_runtime,$dsp_runtime) ;
    return get_configs_freq(1080000,$level,$a9,$m3,$dsp,$a9_runtime,$m3_runtime,$dsp_runtime) ;
  } elsif($level == 1) {
    my $freq = "1080000" ;
    my ($a9_partition,$m3_partition,$dsp_partition) = (0,0,A9_MAX) ;
    $config = $freq."_"."$a9_partition"."-"."$m3_partition"."-"."$dsp_partition" ;
    return get_configs_freq(1080000,$level,$a9_partition,$m3_partition,$dsp_partition,0,0,0) ;
  } elsif($level == 0) {
    my $freq = "1080000" ;
    my ($a9_partition,$m3_partition,$dsp_partition) = (0,A9_MAX,0) ;
    $config = $freq."_"."$a9_partition"."-"."$m3_partition"."-"."$dsp_partition" ;
    return get_configs_freq(1080000,$level,$a9_partition,$m3_partition,$dsp_partition,0,0,0) ;
  } else {
    die "get_config_through_partitioning : invalid level=$level\n" ;
  }
}

sub get_config_satisfying_power
{
  my $level = $_[0] ;
  my $power = $_[1] ;
  my $config = NO_CONFIG ;
  my $config_p = MAX_VAL+1 ;
  
  if($level >= 0) {
    my @configs = get_config_throughput_partitioning_helper($level) ;
    foreach my $c (@configs) {
      #print "get_config_satisfying_power : level=$level : c=$c : r=$config_runtime{$c} : p=<$config_power{$c},$power>\n" ;
      if($config_power{$c} <= $power) {
        $config = $c ;
        last ;
      }
    }

    if($config ne NO_CONFIG) {
      $config_p = $config_power{$config} ;
    }
  }

  return ($config,$config_p) ;
}

sub get_config_list
{
  my $level = $_[0] ;
  if(exists $level_configs{$level}) {
    return @{$level_configs{$level}} ;
  }

  my @config_list ;
  #print "$level\t:\t" ;
  foreach my $f (@freq_list) {
    for(my $a9=0 ; $a9<=A9_MAX ; $a9+=4) {
      for(my $m3=0 ; $m3<=A9_MAX ; $m3+=4) {
        for(my $dsp=0 ; $dsp<=A9_MAX ; $dsp+=4) {
          if($a9+$m3+$dsp != A9_MAX) {
            next ;
          }
          my $c = $f."_".$a9."-".$m3."-".$dsp ;
          my $add_item = 0 ;
          if($level == 0) {
            if($a9==0 and $dsp==0) { $add_item = 1 ; }
          } elsif($level == 1) {
            if($a9==0 and $m3==0) { $add_item = 1 ; }
          } elsif($level == 2) {
            if($a9==0 and ($m3>0) and ($dsp>0)) { $add_item = 1 ; }
          } elsif($level == 3 and ($a9>0) and ($m3>0) and ($dsp>0)) {
            if($f == 300000) { $add_item = 1 ; }
          } elsif($level == 4 and ($a9>0) and ($m3>0) and ($dsp>0)) {
            if($f == 600000) { $add_item = 1 ; }
          } elsif($level == 5 and ($a9>0) and ($m3>0) and ($dsp>0)) {
            if($f == 800000) { $add_item = 1 ; }
          } elsif($level == 6 and ($a9>0) and ($m3>0) and ($dsp>0)) {
            if($f == 1080000) { $add_item = 1 ; }
          }
          if($add_item) {
              push(@config_list,$c) ;
              #print "$c\t" ;
          }
        }
      }
    }
  }
  #print "\n" ;

  $level_configs{$level} = \@config_list ;

  return @config_list ;
}

sub get_mem_scale_factor
{
  if($path_comp[5] eq 'matmul' or $path_comp[5] eq 'doitgen') {
    return MEM_SCALE_FACTOR + 0.1 ;
  } else {
    return MEM_SCALE_FACTOR ;
  }
}

sub get_average_power
{
  my $level = $_[0] ;
  #my @config_list = get_config_list($level) ;

  #my $num_configs = 0 ;
  #my $power = 0 ;
  #foreach my $cfg (@config_list) {
  #  $power += $config_power{$cfg}  ;
  #  $num_configs++ ;
  #}

  #return ($power/$num_configs) ;
  if($level == 6) {
    my $a9_power = $config_power{"1080000_"."64-0-0"} ;
    my $m3_power = $config_power{"1080000_"."0-64-0"} ;
    my $dsp_power = $config_power{"1080000_"."0-0-64"} ;
    return ($a9_power+$m3_power+$dsp_power)*get_mem_scale_factor() ;
  } elsif($level == 5) {
    my $a9_power = $config_power{"800000_"."64-0-0"} ;
    my $m3_power = $config_power{"800000_"."0-64-0"} ;
    my $dsp_power = $config_power{"800000_"."0-0-64"} ;
    return ($a9_power+$m3_power+$dsp_power)*get_mem_scale_factor() ;
  } elsif($level == 4) {
    my $a9_power = $config_power{"600000_"."64-0-0"} ;
    my $m3_power = $config_power{"600000_"."0-64-0"} ;
    my $dsp_power = $config_power{"600000_"."0-0-64"} ;
    return ($a9_power+$m3_power+$dsp_power)*get_mem_scale_factor() ;
  } elsif($level == 3) {
    my $a9_power = $config_power{"300000_"."64-0-0"} ;
    my $m3_power = $config_power{"300000_"."0-64-0"} ;
    my $dsp_power = $config_power{"300000_"."0-0-64"} ;
    return ($a9_power+$m3_power+$dsp_power)*get_mem_scale_factor() ;
  } elsif($level == 2) {
    my $a9_power = 0 ;
    my $freq = "1080000" ;
    my $m3_power = $config_power{$freq."_"."0-64-0"} ;
    my $dsp_power = $config_power{$freq."_"."0-0-64"} ;
    return ($a9_power+$m3_power+$dsp_power) * get_mem_scale_factor() ;
  } elsif($level == 1) {
    my $freq = "1080000" ;
    my ($a9_partition,$m3_partition,$dsp_partition) = (0,0,A9_MAX) ;
    my $config = $freq."_"."$a9_partition"."-"."$m3_partition"."-"."$dsp_partition" ;
    my $dsp_power = $config_power{$config} ;
    return $dsp_power ;
  } elsif($level == 0) {
    my $freq = "1080000" ;
    my ($a9_partition,$m3_partition,$dsp_partition) = (0,A9_MAX,0) ;
    my $config = $freq."_"."$a9_partition"."-"."$m3_partition"."-"."$dsp_partition" ;
    my $m3_power = $config_power{$config} ;
    return $m3_power ;
  } else {
    die "get_config_through_partitioning : invalid level=$level\n" ;
  }
}

sub get_power_list
{
  my $low = $_[0] ;
  my $up = $_[1] ;
  my @power_list ;

  my @p_list = map { 0.01 * $_ } 0 .. 130 ;
  foreach my $p (@p_list) {
    if($p >= $low and $p < $up) {
      push(@power_list, $p) ;
    }
  }
  return @power_list ;
}

sub compute_speed
{
  my $map_ref = $_[0] ;
  my @power_list = map { 0.01 * $_ } 0 .. 130 ;
  my $total_speed = 0 ; 
  foreach my $p (@power_list) {
     my $runtime = ${$map_ref}{$p} ;
     #print "$p : $runtime\n" ;
     $total_speed += (($runtime!=MAX_VAL)?(1/$runtime):0)*0.01 ;
  }
  #print "Total speed = $total_speed\n" ;
  return $total_speed ;
}

sub get_sorted_configs_satisfying_power
{
  my $tmp1_configs = $_[0] ;
  my $power = $_[1] ;
  my @tmp2_configs ;
  foreach my $cfg (@{$tmp1_configs}) {
    #print "get_sorted_configs_satisfying_power : Config = $cfg,Power = $power\n" ;
    if($config_power{$cfg} <= $power) {
      push(@tmp2_configs,$cfg) ;
    }
  }
  my @configs = sort {$config_runtime{$a} <=> $config_runtime{$b}} @tmp2_configs ;
  return @configs ;
}

sub get_config_throughput_partitioning
{
  my $level = $_[0] ;
  my $power = $_[1] ; #Only used for _7_LEVEL and ALL_LEVEL

  if($level >= 0) {
    my @configs ;
    if($level==_7_LEVEL or $level==ALL_LEVEL) {
      my @tmp1_configs ;
      for(my $i=0 ; $i<NUM_LEVEL_7 ; $i++) {
        push(@tmp1_configs,get_config_throughput_partitioning_helper($i)) ;
      }
      @configs = get_sorted_configs_satisfying_power(\@tmp1_configs,$power) ;
    } else {
      @configs = get_config_throughput_partitioning_helper($level) ;
    }
    if((scalar @configs) > 0) {
        return $configs[0] ;
    } else {
      return NO_CONFIG ;
    }
  } else {
    return NO_CONFIG ;
  }
}

sub get_config_average_partitioning
{
  my $level = $_[0] ;
  my $power = $_[1] ; #Only used for _7_LEVEL and ALL_LEVEL
  my $config = NO_CONFIG ;
  if($level == 6) {
    $config = "1080000_"."44-8-12" ;
  } elsif($level == 5) {
    $config = "800000_"."44-8-12" ;
  } elsif($level == 4) {
    $config = "600000_"."40-8-16" ;
  } elsif($level == 3) {
    $config = "300000_"."32-12-20" ;
  } elsif($level == 2) {
    $config = "1080000_"."0-24-40" ;
  } elsif($level == 1) {
    $config = "1080000_"."0-64-0" ;
  } elsif($level == 0) {
    $config = "1080000_"."0-0-64" ;
  } elsif($level == -1) {
    $config = NO_CONFIG ;
  } elsif($level==_7_LEVEL or $level==ALL_LEVEL) {
    my @tmp1_configs ;
    push(@tmp1_configs,"1080000_"."44-8-12") ;
    push(@tmp1_configs,"800000_"."44-8-12") ;
    push(@tmp1_configs,"600000_"."40-8-16") ;
    push(@tmp1_configs,"300000_"."32-12-20") ;
    push(@tmp1_configs,"1080000_"."0-24-40") ;
    push(@tmp1_configs,"1080000_"."0-64-0") ;
    push(@tmp1_configs,"1080000_"."0-0-64") ;
    my @configs ;
    @configs = get_sorted_configs_satisfying_power(\@tmp1_configs,$power) ;
    if((scalar @configs) > 0) {
      $config = $configs[0] ;
    }
  } else {
    die "get_config_average_partitioning : Invalid level $level" ;
  }
  return $config ;
}

sub get_config_best_partitioning
{
  my $cur_level = $_[0] ;
  my $power = $_[1] ;

  my $config_reg_ref = get_configs_ref($cur_level) ;

  my $config_min_runtime = MAX_VAL ;
  my $min_config = NO_CONFIG ;
  foreach my $c (@{$config_reg_ref}) {
    if(($config_power{$c} <= $power) and ($config_runtime{$c} < $config_min_runtime)) {
      $config_min_runtime = $config_runtime{$c} ;
      $min_config = $c ;
    }
  }
  return $min_config ;
}


sub get_configs_ref
{
  my $level = $_[0] ;

  my @config_list ;
  if($level == CPU_ONLY_LEVEL) {
    foreach my $freq (@freq_list) {
      my $c = $freq."_".A9_MAX."-0-0" ;
      push(@config_list, $c) ;
    }
  } elsif($level == ALL_LEVEL) {
    @config_list = keys %config_power ;
  } elsif($level == _7_LEVEL) {
    push(@config_list, get_config_list(0)) ;
    push(@config_list, get_config_list(1)) ;
    push(@config_list, get_config_list(2)) ;
    push(@config_list, get_config_list(3)) ;
    push(@config_list, get_config_list(4)) ;
    push(@config_list, get_config_list(5)) ;
    push(@config_list, get_config_list(6)) ;
  } else { 
    @config_list = get_config_list($level) ;
  }

  return \@config_list ;
}

sub debug_message
{
  my $power_level_setting = $_[0] ;
  my $partition_setting = $_[1] ;
  my $cur_level = $_[2] ;
  my $power = $_[3] ;
  my $runtime = $_[4] ;
  my $config = $_[5] ;

  if(not(($power_level_setting == POWER_7_LEVEL_BMARK_AVG) and ($partition_setting == PART_THROUGHPUT or $partition_setting == PART_BEST))) {
    return ;
  }

  if($power_level_setting == POWER_CPU_ONLY) {
    print "POWER_CPU_ONLY : " ;
  } elsif($power_level_setting == POWER_ALL_LEVEL) {
    print "POWER_ALL_LEVEL : " ;
  } elsif($power_level_setting == POWER_7_LEVEL) {
    print "POWER_7_LEVEL : " ;
  } elsif($power_level_setting == POWER_7_LEVEL_BMARK_AVG) {
    print "POWER_7_LEVEL_BMARK_AVG : " ;
  } elsif($power_level_setting == POWER_7_LEVEL_GLOBAL_AVG) {
    print "POWER_7_LEVEL_GLOBAL_AVG : " ;
  } else {
    die "Unknown power_level_setting $power_level_setting\n" ;
  }

  if($partition_setting == PART_BEST) {
    print "PART_BEST : " ;
  } elsif($partition_setting == PART_THROUGHPUT) {
    print "PART_THROUGHPUT : " ;
  } elsif($partition_setting == PART_AVERAGE) {
    print "PART_AVERAGE : " ;
  } else {
    die "Unknown partition_setting $partition_setting\n" ;
  }

  if($cur_level == ALL_LEVEL) {
    print "ALL_LEVEL : " ;
  } elsif($cur_level == _7_LEVEL) {
    print "_7_LEVEL : " ;
  } elsif($cur_level == CPU_ONLY_LEVEL) {
    print "CPU_ONLY_LEVEL : " ;
  } else {
    print "L$cur_level : " ;
  }

  print "$power : $runtime : $config\n" ;
}

sub create_pareto_map
{
  my $power_level_setting = $_[0] ;
  my $partition_setting = $_[1] ;
  my $config_power_validity = $_[2] ;
  my $pareto_map_ref = $_[3] ;

  my $next_level = 0 ;
  my $cur_level = -1 ;
  my @power_level ;
  if($power_level_setting == POWER_CPU_ONLY) {
    @power_level = (MAX_VAL) ;
    $cur_level = CPU_ONLY_LEVEL ;
  } elsif($power_level_setting == POWER_ALL_LEVEL) {
    @power_level = (MAX_VAL) ;
    $cur_level = ALL_LEVEL ;
  } elsif($power_level_setting == POWER_7_LEVEL) {
    @power_level = (MAX_VAL) ;
    $cur_level = _7_LEVEL ;
  } elsif($power_level_setting == POWER_7_LEVEL_BMARK_AVG) {
    @power_level = (get_average_power(0),get_average_power(1),get_average_power(2),get_average_power(3),get_average_power(4),get_average_power(5),get_average_power(6),1.31) ;
    $cur_level = -1 ;
    print "POWER_7_LEVEL_BMARK_AVG : @power_level\n" ;
  } elsif($power_level_setting == POWER_7_LEVEL_GLOBAL_AVG) {
    @power_level = (0.104239114804935,0.119590340879166,0.180599343792931,0.281277072144409,0.448188356807368,0.631119898218554,0.788036662553024,1.31) ;
    $cur_level = -1 ;
    #print "POWER_7_LEVEL_GLOBAL_AVG : @power_level\n" ;
  } else {
    @power_level = (MAX_VAL) ;
    $cur_level = -1 ;
  }

  my $config = NO_CONFIG ;
  my @power_list = map { 0.01 * $_ } 0 .. 130 ;
  foreach my $p (@power_list) {
    if($p >= $power_level[$next_level]) {
      $cur_level = $next_level ;
      $next_level++ ;
    }

    if($partition_setting == PART_BEST) {
      $config = get_config_best_partitioning($cur_level,$p) ;
    } elsif($partition_setting == PART_THROUGHPUT) {
      die "Invalid level $cur_level" if($power_level_setting == POWER_CPU_ONLY) ;
      $config = get_config_throughput_partitioning($cur_level,$p) ;
    } elsif($partition_setting == PART_AVERAGE) {
      die "Invalid level $cur_level" if($power_level_setting == POWER_CPU_ONLY) ;
      $config = get_config_average_partitioning($cur_level,$p) ;
    } else {
      die "Wrong partition setting $partition_setting\n" ;
    }
    
    if($config eq NO_CONFIG) {
        ${$pareto_map_ref}{$p} = MAX_VAL ;
        debug_message($power_level_setting,$partition_setting,$cur_level,$p,${$pareto_map_ref}{$p},NO_CONFIG) ;
    } else {
      if($config_power{$config} > $p) {
        my $low_runtime = get_runtime_at_lower_level($cur_level,$p,$config) ;
        ${$pareto_map_ref}{$p} = $low_runtime ;
        debug_message($power_level_setting,$partition_setting,$cur_level,$p,${$pareto_map_ref}{$p},"LOWER-CFG") ;
      } else {
        ${$pareto_map_ref}{$p} = $config_runtime{$config} ;
        debug_message($power_level_setting,$partition_setting,$cur_level,$p,${$pareto_map_ref}{$p},$config) ;
      }
    }

  }
}


foreach my $freq (@freq_list) {
  process_power_file($freq) ;
  process_runtime_file($freq) ;
}

foreach my $c (keys %config_runtime) {
  my $runtime = $config_runtime{$c} ;
  my $power = $config_power{$c} ;
  #print "$c : $runtime : $power\n" ;
}


my %a9_dvfs_pareto_map ;
create_pareto_map(POWER_CPU_ONLY,PART_BEST,VALID_OR_INVALID_POWER_CONFIG, \%a9_dvfs_pareto_map) ;
my $a9_dvfs_speed = compute_speed(\%a9_dvfs_pareto_map) ;

########################################################################################################

my %power_all_part_best_map ;
create_pareto_map(POWER_ALL_LEVEL, PART_BEST, VALID_OR_INVALID_POWER_CONFIG, \%power_all_part_best_map) ;
my $power_all_part_best_speed = compute_speed(\%power_all_part_best_map) ;
print "Speedup power_all-best   = ".$power_all_part_best_speed/$a9_dvfs_speed."\n" ;

my %power_all_part_throughput_map ;
create_pareto_map(POWER_ALL_LEVEL, PART_THROUGHPUT, VALID_OR_INVALID_POWER_CONFIG, \%power_all_part_throughput_map) ;
my $power_all_part_throughput_speed = compute_speed(\%power_all_part_throughput_map) ;
print "Speedup power_all-throughput   = ".$power_all_part_throughput_speed/$a9_dvfs_speed."\n" ;

my %power_all_part_average_map ;
create_pareto_map(POWER_ALL_LEVEL, PART_AVERAGE, VALID_OR_INVALID_POWER_CONFIG, \%power_all_part_average_map) ;
my $power_all_part_average_speed = compute_speed(\%power_all_part_average_map) ;
print "Speedup power_all-average   = ".$power_all_part_average_speed/$a9_dvfs_speed."\n" ;

########################################################################################################

my %power_7_level_best_map ;
create_pareto_map(POWER_7_LEVEL, PART_BEST, VALID_OR_INVALID_POWER_CONFIG, \%power_7_level_best_map) ;
my $power_7_level_best_speed = compute_speed(\%power_7_level_best_map) ;
print "Speedup power_7_level-best   = ".$power_7_level_best_speed/$a9_dvfs_speed."\n" ;

my %power_7_level_throughput_map ;
create_pareto_map(POWER_7_LEVEL, PART_THROUGHPUT, VALID_OR_INVALID_POWER_CONFIG, \%power_7_level_throughput_map) ;
my $power_7_level_throughput_speed = compute_speed(\%power_7_level_throughput_map) ;
print "Speedup power_7_level-throughput   = ".$power_7_level_throughput_speed/$a9_dvfs_speed."\n" ;

my %power_7_level_average_map ;
create_pareto_map(POWER_7_LEVEL, PART_AVERAGE, VALID_OR_INVALID_POWER_CONFIG, \%power_7_level_average_map) ;
my $power_7_level_average_speed = compute_speed(\%power_7_level_average_map) ;
print "Speedup power_7_level-average   = ".$power_7_level_average_speed/$a9_dvfs_speed."\n" ;

########################################################################################################

my %power_7_level_bmark_avg_best_map ;
create_pareto_map(POWER_7_LEVEL_BMARK_AVG, PART_BEST, VALID_OR_INVALID_POWER_CONFIG, \%power_7_level_bmark_avg_best_map) ;
my $power_7_level_bmark_avg_best_speed = compute_speed(\%power_7_level_bmark_avg_best_map) ;
print "Speedup power_7_level_bmark_avg-best   = ".$power_7_level_bmark_avg_best_speed/$a9_dvfs_speed."\n" ;

my %power_7_level_bmark_avg_throughput_map ;
create_pareto_map(POWER_7_LEVEL_BMARK_AVG, PART_THROUGHPUT, VALID_OR_INVALID_POWER_CONFIG, \%power_7_level_bmark_avg_throughput_map) ;
my $power_7_level_bmark_avg_throughput_speed = compute_speed(\%power_7_level_bmark_avg_throughput_map) ;
print "Speedup power_7_level_bmark_avg-throughput   = ".$power_7_level_bmark_avg_throughput_speed/$a9_dvfs_speed."\n" ;

my %power_7_level_bmark_avg_average_map ;
create_pareto_map(POWER_7_LEVEL_BMARK_AVG, PART_AVERAGE, VALID_OR_INVALID_POWER_CONFIG, \%power_7_level_bmark_avg_average_map) ;
my $power_7_level_bmark_avg_average_speed = compute_speed(\%power_7_level_bmark_avg_average_map) ;
print "Speedup power_7_level_bmark_avg-average   = ".$power_7_level_bmark_avg_average_speed/$a9_dvfs_speed."\n" ;

########################################################################################################

my %power_7_level_global_avg_best_map ;
create_pareto_map(POWER_7_LEVEL_GLOBAL_AVG, PART_BEST, VALID_OR_INVALID_POWER_CONFIG, \%power_7_level_global_avg_best_map) ;
my $power_7_level_global_avg_best_speed = compute_speed(\%power_7_level_global_avg_best_map) ;
print "Speedup power_7_level_global_avg-best   = ".$power_7_level_global_avg_best_speed/$a9_dvfs_speed."\n" ;

my %power_7_level_global_avg_throughput_map ;
create_pareto_map(POWER_7_LEVEL_GLOBAL_AVG, PART_THROUGHPUT, VALID_OR_INVALID_POWER_CONFIG, \%power_7_level_global_avg_throughput_map) ;
my $power_7_level_global_avg_throughput_speed = compute_speed(\%power_7_level_global_avg_throughput_map) ;
print "Speedup power_7_level_global_avg-throughput   = ".$power_7_level_global_avg_throughput_speed/$a9_dvfs_speed."\n" ;

my %power_7_level_global_avg_average_map ;
create_pareto_map(POWER_7_LEVEL_GLOBAL_AVG, PART_AVERAGE, VALID_OR_INVALID_POWER_CONFIG, \%power_7_level_global_avg_average_map) ;
my $power_7_level_global_avg_average_speed = compute_speed(\%power_7_level_global_avg_average_map) ;
print "Speedup power_7_level_global_avg-average   = ".$power_7_level_global_avg_average_speed/$a9_dvfs_speed."\n" ;
