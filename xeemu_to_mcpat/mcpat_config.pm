#!/usr/bin/perl 

package cache_config ;
sub new
{
    my $class = shift ;
    my $cache_config = shift ;
    my $latency = shift ;
    my $name ;
    my $mcpat_name ;
    my $set ;
    my $bsize ;
    my $assoc ;

    if($cache_config eq "none") {
	    return 0 ;
    } elsif($cache_config =~ m/(\S+):(\d+):(\d+):(\d+):(\S)/) {
	    $name = $1 ;
	    $set = $2 ;
	    $bsize = $3 ;
	    $assoc = $4 ;
    }

    if($name =~ m/(\S)l(\S)/) {
	    $mcpat_name = $1."cache" ;
    }

    my $self = {
	_name => $name ,
        _capacity => $set * $bsize * $assoc,
        _associativity => $assoc,
        _latency => $latency,
        _banks => 1,
        _throughput => 1,
        _block_width => 32,
        _output_width => 32,
        _cache_policy => 1, #Setting as default 1=writeback with write allocate
	_read_accesses => 0,
	_read_misses => 0,
	_write_accesses => 0,
	_write_misses => 0,
	_mcpat_name => $mcpat_name,
	_buffer_sizes => "0, 0, 0, 0",
	_conflicts => 0,
    };
    # Print all the values just for clarification.
    bless $self, $class;
    return $self;
}

sub get_config {
    my( $self ) = @_ ;
    my $config_str = "$self->{_capacity},$self->{_block_width},$self->{_associativity},$self->{_banks},$self->{_throughput},$self->{_latency},$self->{_output_width},$self->{_cache_policy}" ;
    return $config_str ;
}

sub get_mcpat_name {
    my( $self ) = @_ ;
    my $mcpat_name_str = $self->{_mcpat_name} ;
    return $mcpat_name_str ;
}

sub set_read_accesses {
	my ($self, $read_accesses) = @_ ;
	$self->{_read_accesses} = $read_accesses ;
}

sub set_write_accesses {
	my ($self, $write_accesses) = @_ ;
	$self->{_write_accesses} = $write_accesses ;
}

sub set_read_misses {
	my ($self, $read_misses) = @_ ;
	$self->{_read_misses} = $read_misses ;
}

sub set_write_misses {
	my ($self, $write_misses) = @_ ;
	$self->{_write_misses} = $write_misses ;
}

sub get_read_accesses {
	my ($self) = @_ ;
	my $read_accesses = $self->{_read_accesses} ;
	return $read_accesses ;
}

sub get_write_accesses {
	my ($self) = @_ ;
	my $write_accesses = $self->{_write_accesses} ;
	return $write_accesses ;
}

sub get_read_misses {
	my ($self) = @_ ;
	my $read_misses = $self->{_read_misses} ;
	return $read_misses ;
}

sub get_write_misses {
	my ($self) = @_ ;
	my $write_misses = $self->{_write_misses} ;
	return $write_misses ;
}

sub get_buffer_sizes {
	my ($self) = @_ ;
	my $buffer_sizes = $self->{_buffer_sizes} ;
	return $buffer_sizes ;
}

sub get_conflicts {
	my ($self) = @_ ;
	my $conflicts = $self->{_conflicts} ;
	return $conflicts ;
}


package tlb_config ;
sub new
{
    my $class = shift ;
    my $name = shift ;

    my $self = {
	_name => $name ,
	_number_entries => $number_entries,
        _total_accesses => $total_accesses,
        _total_misses => $total_misses,
        _conflicts => $conflicts,
    };
    # Print all the values just for clarification.
    bless $self, $class;
    return $self;
}

sub set_number_entries {
	my ($self, $number_entries) = @_ ;
	$self->{_number_entries} = $number_entries ;
}

sub set_total_accesses {
	my ($self, $total_accesses) = @_ ;
	$self->{_number_entries} = $total_accesses ;
}

sub set_total_misses {
	my ($self, $total_misses) = @_ ;
	$self->{_total_misses} = $total_misses ;
}

sub get_total_misses {
	my ($self) = @_ ;
	my $total_misses = $self->{_total_misses} ;
	return $total_misses ;
}

sub get_total_accesses {
	my ($self) = @_ ;
	my $total_accesses = $self->{_total_accesses} ;
	return $total_accesses ;
}

sub get_number_entries {
	my ($self) = @_ ;
	my $number_entries = $self->{_number_entries} ;
	return $number_entries ;
}

1;
