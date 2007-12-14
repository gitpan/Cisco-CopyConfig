#! /usr/bin/perl

   use strict;
   use Net::SNMP;

   my ($session, $error) = Net::SNMP->session(
      -hostname     => '192.168.3.95',
      -version      =>  3,
      -username     => 'Eug_Test',
#      -authkey      => '0x1adf5ff14d3df84dce26573b7290feaa',
      -authprotocol => 'md5',
      -authpassword => 'Eug_Pass'
#      -privkey      => '0x1adf5ff14d3df84dce26573b7290feaa'
   );

   if (!defined($session)) {
      printf("ERROR: %s.\n", $error);
      exit 1;
   }

   my $sysUptime = '.1.3.6.1.2.1.1.3.0';
   my $result = $session->get_request(
      -varbindlist => [$sysUptime]
   );

   if (!defined($result)) {
      printf("ERROR: %s.\n", $session->error);
      $session->close;
      exit 1;
   }

   printf("sysUptime for host '%s': '%s'\n", 
      $session->hostname, $result->{$sysUptime}
   );

   $session->close;

   exit 0;
