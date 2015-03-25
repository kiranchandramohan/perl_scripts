#!/usr/bin/perl

use mcpat_config ;
use Getopt::Long ;

use constant {
    HEADER => 0,
    SYSTEM => 1,
    CORE => 2,
    FOOTER => 3,
    BEGIN_COMPONENT => 4,
    END_COMPONENT => 5,
    OTHER => 6,
};


$ALIGN_SPACE="    " ;
$current_alignment="" ;
$system_prefix = "system.core0" ;
@mcpat_xml = () ;
%mcpat_objects = () ;
@header_lines = () ;
@system_lines = () ;
@core_lines = () ;
@footer_lines = () ;

sub create_print
{
	my $list_id = $_[0] ;
	my $val = $_[1] ;

	my @tuple_val = (OTHER, $val) ;

	if($list_id == HEADER) {
		push(@header_lines, \@tuple_val) ;
	} elsif($list_id == SYSTEM) {
		push(@system_lines, \@tuple_val) ;
	} elsif($list_id == CORE) {
		push(@core_lines, \@tuple_val) ;
	} elsif($list_id == FOOTER) {
		push(@footer_lines, \@tuple_val) ;
	}
}

sub close_component
{

	my $list_id = $_[0] ;
	my $val = $_[1] ;

	my @tuple_val = (END_COMPONENT, $val) ;

	if($list_id == HEADER) {
		push(@header_lines, \@tuple_val) ;
	} elsif($list_id == SYSTEM) {
		push(@system_lines, \@tuple_val) ;
	} elsif($list_id == CORE) {
		push(@core_lines, \@tuple_val) ;
	} elsif($list_id == FOOTER) {
		push(@footer_lines, \@tuple_val) ;
	}
}

sub create_component
{
	my $list_id = $_[0] ;
	my $id = $_[1] ;
	my $val = $_[2] ;

	my $new_line = "" ;
	my $comp_line = "<component id=\"$id\" name=\"$val\">" ;
	
	my @nl_tuple_val = (OTHER, $new_line) ;
	my @begin_tuple_val = (BEGIN_COMPONENT, $comp_line) ;

	if($list_id == HEADER) {
		push(@header_lines, \@nl_tuple_val) ;
		push(@header_lines, \@begin_tuple_val) ;
	} elsif($list_id == SYSTEM) {
		push(@system_lines, \@nl_tuple_val) ;
		push(@system_lines, \@begin_tuple_val) ;
	} elsif($list_id == CORE) {
		push(@core_lines, \@nl_tuple_val) ;
		push(@core_lines, \@begin_tuple_val) ;
	} elsif($list_id == FOOTER) {
		push(@footer_lines, \@nl_tuple_val) ;
		push(@footer_lines, \@begin_tuple_val) ;
	}
}

sub create_param
{
	my $list_id = $_[0] ;
	my $name = $_[1] ;
	my $value = $_[2] ;

	my $param_line = "<param name=\"$name\" value=\"$value\"/>" ;

	my @param_tuple_val = (OTHER, $param_line) ;
	
	if($list_id == HEADER) {
		push(@header_lines, \@param_tuple_val) ;
	} elsif($list_id == SYSTEM) {
		push(@system_lines, \@param_tuple_val) ;
	} elsif($list_id == CORE) {
		push(@core_lines, \@param_tuple_val) ;
	} elsif($list_id == FOOTER) {
		push(@footer_lines, \@param_tuple_val) ;
	}
}

sub create_stat
{
	my $list_id = $_[0] ;
	my $name = $_[1] ;
	my $value = $_[2] ;

	my $stat_line = "<stat name=\"$name\" value=\"$value\"/>" ;
	my @stat_tuple_val = (OTHER, $stat_line) ;

	if($list_id == HEADER) {
		push(@header_lines, \@stat_tuple_val) ;
	} elsif($list_id == SYSTEM) {
		push(@system_lines, \@stat_tuple_val) ;
	} elsif($list_id == CORE) {
		push(@core_lines, \@stat_tuple_val) ;
	} elsif($list_id == FOOTER) {
		push(@footer_lines, \@stat_tuple_val) ;
	}
}

sub create_default_system_parameters
{
	create_param(SYSTEM, "number_of_cores", "1") ;
        create_param(SYSTEM, "number_of_L1Directories", "0") ;
        create_param(SYSTEM, "number_of_L2Directories", "0") ;
        create_param(SYSTEM, "number_of_L2s", "0") ; 
        create_param(SYSTEM, "Private_L2", "0") ;
        create_param(SYSTEM, "number_of_L3s", "0") ; 
        create_param(SYSTEM, "number_of_NoCs", "0") ;
        create_param(SYSTEM, "homogeneous_cores", "1") ;
        create_param(SYSTEM, "homogeneous_L2s", "1") ;
        create_param(SYSTEM, "homogeneous_L1Directorys", "1") ;
        create_param(SYSTEM, "homogeneous_L2Directorys", "1") ;
        create_param(SYSTEM, "homogeneous_L3s", "1") ;
        create_param(SYSTEM, "homogeneous_ccs", "1") ;
        create_param(SYSTEM, "homogeneous_NoCs", "1") ;
        create_param(SYSTEM, "core_tech_node", "90") ;#<!-- nm -->
        create_param(SYSTEM, "target_core_clockrate", "600") ;#<!--MHz -->
        create_param(SYSTEM, "temperature", "380") ;# <!-- Kelvin -->
        create_param(SYSTEM, "number_cache_levels", "1") ;
	#<!--0: agressive wire technology; 1: conservative wire technology -->
        create_param(SYSTEM, "interconnect_projection_type", "0") ; 
	#<!0:HP(High Perfrmance Type);1:LSTP(Low standby power);2:LOP(Low Operating Power) 
        create_param(SYSTEM, "device_type", "2") ; 
        create_param(SYSTEM, "longer_channel_device", "1") ; #<!-- 0 no use; 1 use when appropriate -->
        create_param(SYSTEM, "machine_bits", "32") ;
        create_param(SYSTEM, "virtual_address_width", "32") ;
        create_param(SYSTEM, "physical_address_width", "32") ;
        create_param(SYSTEM, "virtual_memory_page_size", "8192") ;
	create_param(SYSTEM, "Embedded", "1") ;
}

sub create_default_system_components
{
	#printing to footer to just match EncoreCastle.xml
        create_component(FOOTER, "system.L1Directory0", "L1Directory0") ;
        create_param(FOOTER, "Directory_type", "0") ;
        create_param(FOOTER, "Dir_config", "0,2,0,1,100,100, 8") ;
        create_param(FOOTER, "buffer_sizes", "8, 8, 8, 8") ;
        create_param(FOOTER, "clockrate", "3400") ;
        create_param(FOOTER, "ports", "1,1,1") ;
        create_param(FOOTER, "device_type", "0") ;
        create_stat(FOOTER, "read_accesses", "800000") ;
        create_stat(FOOTER, "write_accesses", "27276") ;
        create_stat(FOOTER, "read_misses", "1632") ;
        create_stat(FOOTER, "write_misses", "183") ;
        create_stat(FOOTER, "conflicts", "20") ;
	close_component(FOOTER, "</component>") ;

        create_component(FOOTER, "system.L2Directory0", "L2Directory0") ;
        create_param(FOOTER, "Directory_type", "0") ;
        create_param(FOOTER, "Dir_config", "0,4,0,1,1, 1") ;
        create_param(FOOTER, "buffer_sizes", "16, 16, 16, 16") ;
        create_param(FOOTER, "clockrate", "1200") ;
        create_param(FOOTER, "ports", "1,1,1") ;
        create_param(FOOTER, "device_type", "0") ;
        create_stat(FOOTER, "read_accesses", "58824") ;
        create_stat(FOOTER, "write_accesses", "27276") ;
        create_stat(FOOTER, "read_misses", "1632") ;
        create_stat(FOOTER, "write_misses", "183") ;
        create_stat(FOOTER, "conflicts", "100") ;
	close_component(FOOTER, "</component>") ;

        create_component(FOOTER, "system.L20", "L20") ;
        create_param(FOOTER, "L2_config", "0,16, 8, 16, 32, 32, 12, 1") ;
        create_param(FOOTER, "buffer_sizes", "16, 16, 16, 16") ;
        create_param(FOOTER, "clockrate", "1200") ;
        create_param(FOOTER, "ports", "1,1,1") ;
        create_param(FOOTER, "device_type", "0") ;
        create_stat(FOOTER, "read_accesses", "200000") ;
        create_stat(FOOTER, "write_accesses", "27276") ;
        create_stat(FOOTER, "read_misses", "1632") ;
        create_stat(FOOTER, "write_misses", "183") ;
        create_stat(FOOTER, "conflicts", "0") ;
        create_stat(FOOTER, "duty_cycle", "1.0") ;
	close_component(FOOTER, "</component>") ;

	create_component(FOOTER, "system.L30", "L30") ;
        create_param(FOOTER, "L3_config", "0,64,16, 16, 16, 100,1") ;
        create_param(FOOTER, "clockrate", "850") ;
        create_param(FOOTER, "ports", "1,1,1") ;
        create_param(FOOTER, "device_type", "0") ;
        create_param(FOOTER, "buffer_sizes", "16, 16, 16, 16") ;
        create_stat(FOOTER, "read_accesses", "11824") ;
        create_stat(FOOTER, "write_accesses", "11276") ;
        create_stat(FOOTER, "read_misses", "1632") ;
        create_stat(FOOTER, "write_misses", "183") ;
        create_stat(FOOTER, "conflicts", "0") ;
        create_stat(FOOTER, "duty_cycle", "1.0") ;
	close_component(FOOTER, "</component>") ;

        create_component(FOOTER, "system.NoC0", "noc0") ;
        create_param(FOOTER, "clockrate", "1200") ;
        create_param(FOOTER, "type", "1") ;
        create_param(FOOTER, "horizontal_nodes", "0") ;
        create_param(FOOTER, "vertical_nodes", "0") ;
        create_param(FOOTER, "has_global_link", "0") ;
        create_param(FOOTER, "link_throughput", "1") ;
        create_param(FOOTER, "link_latency", "1") ;
        create_param(FOOTER, "input_ports", "0") ;
        create_param(FOOTER, "output_ports", "0") ;
        create_param(FOOTER, "virtual_channel_per_port", "0") ;
        create_param(FOOTER, "input_buffer_entries_per_vc", "0") ;
        create_param(FOOTER, "flit_bits", "40") ;
        create_param(FOOTER, "chip_coverage", "1") ;
        create_param(FOOTER, "link_routing_over_percentage", "1.0") ;
        create_stat(FOOTER, "total_accesses", "0") ;
        create_stat(FOOTER, "duty_cycle", "1") ;
	close_component(FOOTER, "</component>") ;

        create_component(FOOTER, "system.mem", "mem") ;
        create_param(FOOTER, "mem_tech_node", "180") ;
        create_param(FOOTER, "device_clock", "200") ;
        create_param(FOOTER, "peak_transfer_rate", "6400") ;
        create_param(FOOTER, "internal_prefetch_of_DRAM_chip", "4") ;
        create_param(FOOTER, "capacity_per_channel", "0") ;
        create_param(FOOTER, "number_ranks", "0") ;
        create_param(FOOTER, "num_banks_of_DRAM_chip", "0") ;
        create_param(FOOTER, "Block_width_of_DRAM_chip", "0") ;
        create_param(FOOTER, "output_width_of_DRAM_chip", "0") ;
        create_param(FOOTER, "page_size_of_DRAM_chip", "0") ;
        create_param(FOOTER, "burstlength_of_DRAM_chip", "0") ;
        create_stat(FOOTER, "memory_accesses", "0") ;
        create_stat(FOOTER, "memory_reads", "0") ;
        create_stat(FOOTER, "memory_writes", "0") ;
	close_component(FOOTER, "</component>") ;

        create_component(FOOTER, "system.mc", "mc") ;
        create_param(FOOTER, "type", "0") ;
        create_param(FOOTER, "mc_clock", "800") ;
        create_param(FOOTER, "peak_transfer_rate", "1600") ;
        create_param(FOOTER, "block_size", "16") ;
        create_param(FOOTER, "number_mcs", "0") ;
        create_param(FOOTER, "memory_channels_per_mc", "2") ;
        create_param(FOOTER, "number_ranks", "2") ;
        create_param(FOOTER, "withPHY", "0") ;
        create_param(FOOTER, "req_window_size_per_channel", "32") ;
        create_param(FOOTER, "IO_buffer_size_per_channel", "32") ;
        create_param(FOOTER, "databus_width", "32") ;
        create_param(FOOTER, "addressbus_width", "32") ;
        create_stat(FOOTER, "memory_accesses", "6666") ;
        create_stat(FOOTER, "memory_reads", "3333") ;
        create_stat(FOOTER, "memory_writes", "3333") ;
	close_component(FOOTER, "</component>") ;

	create_component(FOOTER, "system.niu", "niu") ;
	create_param(FOOTER, "type", "0") ;
	create_param(FOOTER, "clockrate", "350") ;
	create_param(FOOTER, "number_units", "0") ; 
	create_stat(FOOTER, "duty_cycle", "1.0") ; 
	create_stat(FOOTER, "total_load_perc", "0.7") ;
	close_component(FOOTER, "</component>") ;

        create_component(FOOTER, "system.pcie", "pcie") ;
        create_param(FOOTER, "type", "0") ;
        create_param(FOOTER, "withPHY", "1") ;
        create_param(FOOTER, "clockrate", "350") ;
        create_param(FOOTER, "number_units", "0") ;
        create_param(FOOTER, "num_channels", "8") ;
        create_stat(FOOTER, "duty_cycle", "1.0") ;
        create_stat(FOOTER, "total_load_perc", "0.7") ;
	close_component(FOOTER, "</component>") ;

        create_component(FOOTER, "system.flashc", "flashc") ;
        create_param(FOOTER, "number_flashcs", "0") ;
        create_param(FOOTER, "type", "1") ;
        create_param(FOOTER, "withPHY", "1") ;
        create_param(FOOTER, "peak_transfer_rate", "200") ;
        create_stat(FOOTER, "duty_cycle", "1.0") ;
        create_stat(FOOTER, "total_load_perc", "0.7") ;
	close_component(FOOTER, "</component>") ;
}

sub create_default_core_parameters
{
	create_param(CORE, "clock_rate", "600") ;             
	create_param(CORE, "opt_local", "0") ;                 
	create_param(CORE, "instruction_length", "32") ;               
	create_param(CORE, "opcode_width", "7") ;                      
	create_param(CORE, "x86", "0") ;                       
	create_param(CORE, "micro_opcode_width", "0") ;                
	create_param(CORE, "machine_type", "1") ;
	create_param(CORE, "number_hardware_threads", "1") ;   
	create_param(CORE, "fetch_width", "8") ;
	create_param(CORE, "number_instruction_fetch_ports", "1") ;    
	create_param(CORE, "decode_width", "0") ;
	create_param(CORE, "issue_width", "0") ;
	create_param(CORE, "peak_issue_width", "0") ;  
	create_param(CORE, "commit_width", "0") ;
	create_param(CORE, "fp_issue_width", "0") ;    
	create_param(CORE, "prediction_width", "0") ;  
	create_param(CORE, "pipelines_per_core", "1,0") ;
	create_param(CORE, "pipeline_depth", "5,0") ;  

	create_param(CORE, "instruction_buffer_size", "0") ;   
	create_param(CORE, "decoded_stream_buffer_size", "0") ;
	create_param(CORE, "instruction_window_scheme", "0") ; 
	create_param(CORE, "instruction_window_size", "1") ;   
	create_param(CORE, "fp_instruction_window_size", "0") ;
	create_param(CORE, "ROB_size", "0") ;  
	create_param(CORE, "archi_Regs_IRF_size", "32") ;
	create_param(CORE, "archi_Regs_FRF_size", "0") ;
	create_param(CORE, "phy_Regs_IRF_size", "32") ;
	create_param(CORE, "phy_Regs_FRF_size", "0") ; 
	create_param(CORE, "rename_scheme", "1") ;     
	create_param(CORE, "register_windows_size", "0") ;     
	create_param(CORE, "LSU_order", "inorder") ;   
	create_param(CORE, "store_buffer_size", "1") ; 
	create_param(CORE, "load_buffer_size", "0") ;  
	create_param(CORE, "memory_ports", "1") ;
	create_param(CORE, "RAS_size", "0") ;  

	create_stat(CORE, "int_instructions", "200000") ;
	create_stat(CORE, "fp_instructions", "0") ;                                                                              
	create_stat(CORE, "committed_instructions", "300000") ;                                                        
	create_stat(CORE, "committed_int_instructions", "200000") ;                                                          
	create_stat(CORE, "committed_fp_instructions", "0") ;                                                                      
	create_stat(CORE, "pipeline_duty_cycle", "1") ;                                       
	create_stat(CORE, "total_cycles", "100000") ;                                                                     
	create_stat(CORE, "idle_cycles", "0") ;
	create_stat(CORE, "busy_cycles" , "100000") ;                                                                   
	create_stat(CORE, "ROB_reads", "0") ;                                                                                  
	create_stat(CORE, "ROB_writes", "0") ;                                                                  
	create_stat(CORE, "rename_reads", "0") ;                                               
	create_stat(CORE, "rename_writes", "0") ;                                              
	create_stat(CORE, "fp_rename_reads", "0") ;
	create_stat(CORE, "fp_rename_writes", "0") ;
	create_stat(CORE, "inst_window_reads", "0") ;
	create_stat(CORE, "inst_window_writes", "0") ;                                                                            
	create_stat(CORE, "inst_window_wakeup_accesses", "0") ;
	create_stat(CORE, "fp_inst_window_reads", "0") ;                                                                          
	create_stat(CORE, "fp_inst_window_writes", "0") ;
	create_stat(CORE, "fp_inst_window_wakeup_accesses", "0") ;
	create_stat(CORE, "int_regfile_reads", "600000") ;
	create_stat(CORE, "float_regfile_reads", "0") ;  
	create_stat(CORE, "int_regfile_writes", "300000") ;
	create_stat(CORE, "float_regfile_writes", "0") ;
	create_stat(CORE, "function_calls", "5") ;
	create_stat(CORE, "context_switches", "0") ;

	create_stat(CORE, "cdb_alu_accesses", "200000") ;
        create_stat(CORE, "cdb_mul_accesses", "200000") ;
        create_stat(CORE, "cdb_fpu_accesses", "0") ;
     
        create_stat(CORE, "IFU_duty_cycle", "1") ;                     
        create_stat(CORE, "LSU_duty_cycle", "0.5") ;
        create_stat(CORE, "MemManU_I_duty_cycle", "1") ;
        create_stat(CORE, "MemManU_D_duty_cycle", "0.5") ;
        create_stat(CORE, "ALU_duty_cycle", "1") ;
        create_stat(CORE, "MUL_duty_cycle", "0.3") ;
        create_stat(CORE, "FPU_duty_cycle", "0.3") ;
        create_stat(CORE, "ALU_cdb_duty_cycle", "1") ;
        create_stat(CORE, "MUL_cdb_duty_cycle", "0.3") ;
        create_stat(CORE, "FPU_cdb_duty_cycle", "0.3") ;
        create_param(CORE, "number_of_BPT", "0") ;

	create_param(CORE, "number_of_BTB", "0") ;
}

sub create_default_core_components
{
	create_component(CORE, "system.core0.itlb", "itlb") ;
	create_param(CORE, "number_entries", "0") ;
	create_stat(CORE, "total_accesses", "0") ;
	create_stat(CORE, "total_misses", "0") ;
	create_stat(CORE, "conflicts", "0") ;
	close_component(CORE, "</component>") ;

	create_component(CORE, "system.core0.dtlb", "dtlb") ;
	create_param(CORE, "number_entries", "0") ;
	create_stat(CORE, "total_accesses", "0") ;
	create_stat(CORE, "total_misses", "0") ;
	create_stat(CORE, "conflicts", "0") ;
	close_component(CORE, "</component>") ;

        create_component(CORE, "system.core0.predictor", "PBT") ;
        create_param(CORE, "local_predictor_size", "0,0") ;
        create_param(CORE, "local_predictor_entries", "0") ;
        create_param(CORE, "global_predictor_entries", "0") ;
        create_param(CORE, "global_predictor_bits", "0") ;
        create_param(CORE, "chooser_predictor_entries", "0") ;
        create_param(CORE, "chooser_predictor_bits", "0") ;
	close_component(CORE, "</component>") ;

        create_component(CORE, "system.core0.BTB", "BTB") ;
        create_param(CORE, "BTB_config", "6144,4,2,1, 1,3") ;
        create_stat(CORE, "read_accesses", "0") ;
        create_stat(CORE, "write_accesses", "0") ;
	close_component(CORE, "</component>") ;
	
	close_component(CORE, "</component>") ;
}

sub parse_get_val
{
	my $parse_str = $_[0] ;
	my $line = $_[1] ;

	my $val = -1 ;
	if($line =~ m/$parse_str:\s*(\d+)/) {
		#print "Match for $parse_str\n" ;
		$val = $1 ;
	} else {
		#print "No match\n" ;
	}

	return $val ;
}

sub parse_simulator
{
	my @read_lines ;
	my @lines = @{$_[0]} ;
	my $prev_line_val ;
	my $fpu_per_core = 0 ;
	foreach my $line (@lines) {
		chomp($line) ;
		if($line =~ m/^-cache:(\S+)lat\s+(\d+)\s#\s([\S\s]*)/) {
			#print "sim cache lat : $1, $2, $3\n" ;
			my $name = $1 ;
			my $latency = $2 ;
			my $cache = new cache_config($prev_line_val, $latency) ;
			if($cache) {
				$mcpat_objects{$name} = $cache ;
			}
		} elsif($line =~ m/^-cache:(\S+)\s+(\S+)\s#\s([\S\s]*)/) {
			#print "sim cache : $1, $2, $3\n" ;
			$prev_line_val = $2 ;
		} elsif($line =~ m/^-res:(\S+)\s+(\d+)\s#\s([\S\s]*)/) {
			$quantity = $1 ;
			$val = $2 ;
			if($quantity eq "ialu") {
				create_param(CORE, "ALU_per_core", $val) ;
			} elsif($quantity eq "imult") {
				create_param(CORE, "MUL_per_core", $val) ;
			} elsif($quantity eq "fpalu") {
				$fpu_per_core += $val ;
			} elsif($quantity eq "fpmult") {
				$fpu_per_core += $val ;
			}
		} elsif($line =~ m/^Simulation Characteristics/) {
			last ;
		} else {
			#print "sim : NOT COVERED : $line\n" ;
		}
	}

	create_param(CORE, "FPU_per_core", $fpu_per_core) ;
	close(FILE) ;
}

sub parse_simulation_characteristics
{
	my $panalyzer_config ;
	my $prev_panalyzer_config ;
	my @read_lines ;
	my @lines = @{$_[0]} ;
	my $total_mispredictions = 0 ;
	my $total_cycles = 0 ;
	foreach my $line (@lines) {
		chomp($line) ;
		if($line =~ m/\s*(\S*)\s*panalyzer\s*configuration/) {
		} elsif($line =~ m/([\s\S]+)\s*:\s*(\d+)/) {
		} elsif($line =~ m/^-(\S+)\s+(\S+)\s#\s(\S*)/) {
		} elsif($line =~ m/^#/) {
		} elsif($line =~ m/(\S+\s\S+)\s+(\S+\.?\S*)\s#\s([\s\S]+)/) {
			my $quantity = $1 ;
			my $val = $2 ;
	        	if($quantity eq "alu access") {
				create_stat(CORE, "ialu_accesses", $val) ;    
                        } elsif($quantity eq "mult access") {
				create_stat(CORE, "mul_accesses", $val) ;
			} elsif($quantity eq "fpu access") {
				create_stat(CORE, "fpu_accesses", $val) ;
			}
		} elsif($line =~ m/(\S+)\s+(\S+\.?\S*)\s#\s([\s\S]+)/) {
			my $quantity = $1 ;
			my $val = $2 ;
			#print "sim characteristics : <$1,$2>\n" ;
			if($quantity eq "sim_cycle") {
				create_stat(SYSTEM, "total_cycles", $val) ;
				$total_cycles = $val ;
			} elsif($quantity eq "sim_idle_cycle") {
				create_stat(SYSTEM, "idle_cycles", $val) ;
				create_stat(SYSTEM, "busy_cycles", $total_cycles-$val) ;
			} elsif($quantity eq "sim_num_insn") { 
				create_stat(CORE, "total_instructions", $val) ;
			} elsif($quantity eq "sim_num_loads") {
				create_stat(CORE, "load_instructions", $val) ;
			} elsif($quantity eq "sim_num_stores") {
				create_stat(CORE, "store_instructions", $val) ;
			} elsif($quantity eq "sim_num_branches") {
				create_stat(CORE, "branch_instructions", $val) ;
			} elsif($quantity eq "sim_mispred_taken") {
				$total_mispredictions += $val ;
			} elsif($quantity eq "sim_mispred_nottaken") {
				$total_mispredictions += $val ;
			} elsif($quantity =~ m/(\S+)\.(\S+)/) {
				my $name = $1 ;
				my $type = $2 ;
				if(($name eq "il1") or ($name eq "dl1")) {
					if($type eq "accesses") {
						$mcpat_objects{$name}->set_read_accesses($val) ;
					} elsif($type eq "misses") {
						$mcpat_objects{$name}->set_read_misses($val) ;
					} 
					#my $mcpat_name = $mcpat_objects{$name}->get_mcpat_name() ;
					#print "name = $name, $mcpat_name\n" ;
				}
			}
			#print "sc1 : $1, $2, $3\n" ;
			push(@read_lines, $line) ;
		} else {
			#print "sc2 : NOT COVERED : $line\n" ;
		}
	}

	create_stat(CORE, "branch_mispredictions", $total_mispredictions) ;

	my $icache = $mcpat_objects{'il1'} ;
	my $icache_name_str = $icache->get_mcpat_name() ;
	create_component(CORE, "system.core0".".".$icache_name_str, $icache_name_str) ;
	create_param(CORE, $icache_name_str."_config", $icache->get_config()) ;
	create_param(CORE, "buffer_sizes", $icache->get_buffer_sizes()) ;
	create_stat(CORE, "read_accesses", $icache->get_read_accesses()) ;
	create_stat(CORE, "read_misses", $icache->get_read_misses()) ;
	create_stat(CORE, "conflicts", $icache->get_conflicts()) ;
	close_component(CORE, "</component>") ;

	my $dcache = $mcpat_objects{'dl1'} ;
	my $dcache_name_str = $dcache->get_mcpat_name() ;
	create_component(CORE, "system.core0".".".$dcache_name_str, $dcache_name_str) ;
	create_param(CORE, $dcache_name_str."_config", $dcache->get_config()) ;
	create_param(CORE, "buffer_sizes", $dcache_buffer_sizes) ;
	create_stat(CORE, "read_accesses", $dcache->get_read_accesses()) ;
	create_stat(CORE, "read_misses", $dcache->get_read_misses()) ;
	create_stat(CORE, "write_accesses", $dcache->get_write_accesses()) ; #KC : Not populated in the first place
	create_stat(CORE, "write_misses", $dcache->get_write_misses()) ; #KC : Not populated in the first place
	create_stat(CORE, "conflicts", $dcache->get_conflicts()) ;
	close_component(CORE, "</component>") ;

	close(FILE) ;
}

sub parse_misc
{
	my $panalyzer_config ;
	my $prev_panalyzer_config ;
	my @read_lines ;
	my @lines = @{$_[0]} ;
	foreach my $line (@lines) {
		chomp($line) ;
		print "$line\n" ;
		if($line =~ m/\s*(\S*)\s*panalyzer\s*configuration/) {
		} elsif($line =~ m/([\s\S]+)\s*:\s*(\d+)/) {
		} elsif($line =~ m/-(\S+)\s+(\S+)\s#\s(\S*)/) {
		} elsif($line =~ m/(\S+\s?\S*)\s+(\S+\.?\S*)\s#\s([\s\S]+)/) {
		} elsif($line =~ m/(\S*)\s?name:\s(\S+)/) {
			#print "misc1 : $1 = $2 = $3\n" ;
			push(@read_lines, $line) ;
		} elsif($line =~ m/pmodel type:\s(\S*)/) {
			#print "misc2 : pmodel type = $1\n" ;
			push(@read_lines, $line) ;
		} elsif($line =~ m/strip_length = (\S*)/) {
			#print "misc3 : strip_length = $1\n" ;
			push(@read_lines, $line) ;
		} elsif($line =~ m/microCeff (\S*)/) {
			#print "misc4 : microCeff $1\n" ;
			push(@read_lines, $line) ;
		} elsif($line =~ m/clock tree style: (\S*)/) {
			#print "misc5 : clock tree style: $1\n" ;
			push(@read_lines, $line) ;
		} elsif($line =~ m/([\s\S]+)\s*:\s*(\d+)/) {
			#print "misc6 : $1 = $2\n" ;
			push(@read_lines, $line) ;
		} else {
			#print "misc7 : NOT COVERED : $line\n" ;
		}
	}
	close (FILE) ;
}

sub create_mcpat_header
{
	my $mcpat_xml = $_[0] ;
	my $xml_header= '<?xml version="1.0" ?>' ;
	create_print(HEADER, $xml_header) ;
	create_component(HEADER, "root", "root") ;
	create_component(HEADER, "system", "system") ;
	create_default_system_parameters() ;
	create_component(CORE, "system.core0", "core0") ;
}

sub create_mcpat_footer
{
	create_default_system_components() ;
	create_print(FOOTER, "") ;

	close_component(FOOTER, "</component>") ;
	close_component(FOOTER, "</component>") ;
}

sub parse_input_file
{
	my $sim_file = $_[0] ;
	my @panalyzer_lines = () ;
	my @simulator_lines = () ;
	my @simulation_characteristics_lines = () ;
	my @misc_lines = () ;

	my $panalyzer_scope = 1 ;
	my $simulator_scope = 0 ;
	my $simulation_characteristics_scope = 0 ;

	open FILE, $sim_file or die("Could not open file.");
	foreach $line (<FILE>) {
		chomp($line) ;
		if($line =~ m/^#/) { #Ignore comments
		} elsif($line =~ m/^Command line:/) {
			$panalyzer_scope = 0 ;
			$simulator_scope = 1 ;
		} elsif($line =~ m/^Simulation Characteristics/) {
			$simulator_scope = 0 ;
			$simulation_characteristics_scope = 1 ;
		}elsif($panalyzer_scope and 
		      ($line =~ m/\s*(\S*)\s*panalyzer\s*configuration/)) {
			push(@panalyzer_lines, $line) ;
		} elsif($panalyzer_scope and 
			($line =~ m/([\s\S]+)\s*:\s*(\d+)/)) {
			push(@panalyzer_lines, $line) ;
		} elsif($simulator_scope and ($line =~ m/-(\S+)\s+(\S+)\s#\s(\S*)/)) {
			push(@simulator_lines, $line) ;
		} elsif($simulation_characteristics_scope and 
			$line =~ m/(\S+\s?\S*)\s+(\S+\.?\S*)\s#\s([\s\S]+)/) {
			push(@simulation_characteristics_lines, $line) ;
		} elsif($line =~ m/(\S*)\s?name:\s(\S+)/) {
			push(@misc_lines, $line) ;
		} elsif($line =~ m/pmodel type:\s(\S*)/) {
			push(@misc_lines, $line) ;
		} elsif($line =~ m/strip_length = (\S*)/) {
			push(@misc_lines, $line) ;
		} elsif($line =~ m/microCeff (\S*)/) {
			push(@misc_lines, $line) ;
		} elsif($line =~ m/clock tree style: (\S*)/) {
			push(@misc_lines, $line) ;
		} elsif($line =~ m/([\s\S]+)\s*:\s*(\d+)/) {
			push(@misc_lines, $line) ;
		} else {
			#print "NOT COVERED : $line\n" ;
		}
	}
	close (FILE) ;

	#parse_panalyzer(\@panalyzer_lines) ;
	parse_simulator(\@simulator_lines) ;
	parse_simulation_characteristics(\@simulation_characteristics_lines) ;
	#parse_misc(\@misc_lines) ;
}

sub process_alignment
{
	my $fh = $_[0] ;
	my $indent = $_[1] ;
	if($indent == BEGIN_COMPONENT) {
	        print $fh "$current_alignment" ;
		$current_alignment = $current_alignment.$ALIGN_SPACE ;
	} elsif($indent == END_COMPONENT) {
		my $offset = length($current_alignment) - length($ALIGN_SPACE) ;
		$current_alignment = substr($current_alignment, 0, $offset) ;
		print $fh "$current_alignment" ;
	} elsif($indent == OTHER) {
		print $fh "$current_alignment" ;
	}
}

sub print_xml
{
	my $ofile = $_[0] ;
	open FILE, ">$ofile" or die("Could not open file.");
	foreach my $hl (@header_lines) {
		my $indent = $hl->[0] ;
		my $l = $hl->[1] ;
		process_alignment(FILE, $indent) ;
		print FILE "$l\n" ;
	}
	foreach my $sl (@system_lines) {
		my $indent = $sl->[0] ;
		my $l = $sl->[1] ;
		process_alignment(FILE, $indent) ;
		print FILE "$l\n" ;
	}
	foreach my $cl (@core_lines) {
		my $indent = $cl->[0] ;
		my $l = $cl->[1] ;
		process_alignment(FILE, $indent) ;
		print FILE "$l\n" ;
	}
	foreach my $fl (@footer_lines) {
		my $indent = $fl->[0] ;
		my $l = $fl->[1] ;
		process_alignment(FILE, $indent) ;
		print FILE "$l\n" ;
	}
	close (FILE) ;
}

my $ifile = 'sim' ;
my $ofile = 'mcpat.xml' ;
my $help  = '' ;

GetOptions(
    'ifile=s' => \$ifile,
    'ofile=s' => \$ofile,
    'help!'   => \$help,
) or die "Incorrect usage!\n";

if( $help ) { 
    print "Usage : sim_parse.pl -ifile <input file name> -ofile <output file name>\n";
    exit 0 ;
}

create_mcpat_header() ;
parse_input_file($ifile) ;
create_default_core_parameters ;
create_default_core_components ;
create_mcpat_footer() ;
print_xml($ofile) ;
