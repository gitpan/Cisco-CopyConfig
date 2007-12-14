#! /usr/bin/perl

   use strict;
   use Net::SNMP;

   my ($session, $error) = Net::SNMP->session(
      -hostname     => '192.168.3.95',
      -version      =>  3,
      -username     => 'Eug_Pass_enc',
      -authkey      => '0x1adf5ff14d3df84dce26573b7290feaa',
      -authprotocol => 'md5',
      -privkey      => '0x1adf5ff14d3df84dce26573b7290feaa'
   );

   if (!defined($session)) {
      printf("ERROR: %s.\n", $error);
      exit 1;
   }

   my $sysContact = '1.3.6.1.2.1.1.4.0';

   my $result = $session->set_request(
      -varbindlist => [$sysContact, OCTET_STRING, 'Help Desk x911']
   );

   if (!defined($result)) {
      printf("ERROR: %s.\n", $session->error);
      $session->close;
      exit 1;
   }

   printf("sysContact for host '%s' set to '%s'\n", 
      $session->hostname, $result->{$sysContact}
   );

   $session->close;

   exit 0;
