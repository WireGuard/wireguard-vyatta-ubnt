#!/usr/bin/perl

use lib "/opt/vyatta/share/perl5/";
use Vyatta::Config;

use NetAddr::IP qw(:lower);
use Getopt::Long;

use strict;

sub usage {
    print "Usage: ${0} --intf <interface> [--peer <peer>]\n";
    exit 1;
}

my ($intf, $peer, @allowed_ips);

GetOptions("intf=s"           => \$intf,
           "peer=s"           => \$peer,
) or usage();

usage() unless $intf;
check_peer($intf, $peer) if $intf && $peer;
check_interface($intf) if $intf && !$peer;

exit 0;

# Validate that allowed-ips are assigned to only one peer on an interface
sub check_interface {
    my ($intf) = @_;
    my @allowed_ips;
    my $config = new Vyatta::Config;
    my $path = "interfaces wireguard ${intf}";
    die "${0} error: invlaid interface\n" unless $config->exists($path);

    # Get allowed-ips for all peers on the interface
    $config->setLevel("${path} peer");
    push @allowed_ips, peer_allowed_ips("${path} peer ${_}") for $config->listNodes();

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
sub check_peer {
    my ($intf, $peer) = @_;
    my $config = new Vyatta::Config;
    my $path = "interfaces wireguard ${intf} peer ${peer}";
    die "${0} error: invlaid interface and/or peer\n" unless $config->exists($path);
    
    # Get allowed-ips for the peer
    @allowed_ips = peer_allowed_ips($path);
    
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

# Returns an array containing all allowed-ips assigned to a peer
sub peer_allowed_ips {
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
