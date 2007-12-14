#!/usr/bin/perl -w

    use strict;
    use Cisco::CopyConfig ();

        my $tftp_ip    = '192.168.3.13';
        my $tftp_file  = 'config/router2';
        my $cisco_ip   = '192.168.3.95';
        my $comm_s     = 'aassddff';
        my $snmp_ver   = 1; #2,3
        my $config     = Cisco::CopyConfig->new(
                             Host => $cisco_ip,
                             Comm => $comm_s,
                             Snmp_Ver => $snmp_ver
                );
        print "$config->{err}\n" unless $config->copy($tftp_ip, $tftp_file);

