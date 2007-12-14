#!/usr/bin/perl
#### for snmp version 3
use strict;
use Cisco::CopyConfig ();
use Socket;

my @array;

while (<>) {
  chomp;  # avoid \n on last field
  @array = split(/ /);
  if ( $array[10] eq "%SYS-5-CONFIG_I:" ) {
  
        my $tftp_file;
        my $tftp_ip    = '192.168.3.13';
        my $cisco_ip   = $array[4];
	my $name = gethostbyaddr( inet_aton( $cisco_ip ), AF_INET );
	if ( $name ) {
          $tftp_file  = "config/$name";
	} else {
          $tftp_file  = "config/$cisco_ip";
	}
        my $snmp_ver   = 3;
        my $config     = Cisco::CopyConfig->new(
                             Host => $cisco_ip,
                             Snmp_Ver => $snmp_ver,
                             User => 'Eug_Test_enc',
                             User_Pass => 'Eug_Pass',
                             Auth_Proto => 'md5',
                             Sec_Pass => 'Eug_Pass_enc',
                             Sec_Proto => 'des'
        		     );
        print "$config->{err}\n" unless $config->copy($tftp_ip, $tftp_file);

  }
}

exit 0;
