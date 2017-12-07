#!/usr/bin/perl

use lib "/opt/vyatta/share/perl5/";
use Vyatta::Config;

use NetAddr::IP qw(:lower);
use Getopt::Long;

use strict;

sub usage {
    print <<EOF;
Usage: $0 --intf <interface>
       $0 --intf <interface> --peer <peer>
       $0  --allowed-ips <ip_address ...>
EOF
    exit 1;
}

my ($intf, $peer, @allowed_ips);

GetOptions("intf=s"           => \$intf,
           "peer=s"           => \$peer,
           "allowed-ips=s{,}" => \@allowed_ips,
) or usage();

is_valid_allowed_ips(@allowed_ips) if @allowed_ips;
is_valid_peer($intf, $peer) if $peer && $intf;
is_valid_interface($intf, $peer) if $intf && !$peer && !@allowed_ips;

exit 0;

# Validate that allowed-ips are assigned to only one peer on an interface
sub is_valid_interface {
    my ($intf) = @_;
    my @allowed_ips;
    my $config = new Vyatta::Config;
    my $path = "interfaces wireguard ${intf}";
    die "${0} error: invlaid interface\n" unless $config->exists($path);

    # Get allowed-ips for all peers on the interface
    $config->setLevel("${path} peer");
    push @allowed_ips, get_peer_allowed_ips("${path} peer ${_}") for $config->listNodes();

    # Get array containing any duplicate members of @allowed_ips
    my @duplicates = duplicates(@allowed_ips);
    
    # If there are duplicates raise an error message for each and die.
    # IPv6 addresses are converted to their short format to comply with RFC5952
    if (@duplicates) {
        my $err_str;
        foreach (@duplicates) {
            $err_str .= "Error: Allowed IP " . ($_->version() == 4 ? $_ : $_->short()) . " assigned to multiple peers on interface ${intf}\n";
        }
        die $err_str;
    }
    return; 
}

# Validate that peer doesn't contain duplicate allowed-ips
sub is_valid_peer {
    my ($intf, $peer) = @_;
    my $config = new Vyatta::Config;
    my $path = "interfaces wireguard ${intf} peer ${peer}";
    die "${0} error: invlaid interface and/or peer\n" unless $config->exists($path);
    
    # Get allowed-ips for the peer
    @allowed_ips = get_peer_allowed_ips($path);
    
    # Get array containing any duplicate members of @allowed_ips
    my @duplicates = duplicates(@allowed_ips);
    
    # If there are duplicates raise an error message for each and die.
    # IPv6 addresses are converted to their short format to comply with RFC5952
    if (@duplicates) {
        my $err_str;
        foreach (@duplicates) {
            $err_str .= "Error: Allowed IP " . ($_->version() == 4 ? $_ : $_->short()) . " appears multiple times on interface ${intf} peer ${peer}\n";
        }
        die $err_str;
    }
    
    return;
}

# Validate that the allowed-ips list provided contains valid ip addresses
sub is_valid_allowed_ips {
    my (@allowed_ips, $print_ips) = @_;
    @allowed_ips = split(/,/,join(',',@allowed_ips));

    for (@allowed_ips) {
        my $ip = new NetAddr::IP->new($_);
        die "Error: Allowed IP ${_} is not a valid IP address\n" unless $ip;
    }

    return;
}

# Get an array containing all allowed-ips assigned to a peer
sub get_peer_allowed_ips {
    my ($peer) = @_;
    my @allowed_ips;

    my $config = new Vyatta::Config;
    $config->setLevel($peer);
    my @peer_allowed_ips = $config->returnValues("allowed-ips");
    foreach (@peer_allowed_ips) {
        push @allowed_ips, new NetAddr::IP->new($_) for split(/,/, $_);    
    }
    
    return @allowed_ips;
}

# Return an array containing any non-unique members of the provided array
sub duplicates {
    my (@array) = @_;
    my %seen;
    
    return grep { $seen{ $_ }++ } @array;
}
