#!/usr/bin/perl -w
###
### $Id: CopyConfig.pm,v 1.2 2003/03/20 08:16:44 aaronsca Exp $
###
### -- Manipulate running-config of devices running IOS
###

package Cisco::CopyConfig;
use strict;
use Socket;
use Exporter;
use Net::SNMP;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION	= '$Revision: 1.2 $ ' =~ /\$Revision:\s+([^\s]+)/;
@ISA		= qw(Exporter);
@EXPORT		= ();
@EXPORT_OK	= (
  'ccCopyProtocol', 'ccCopySourceFileType', 'ccCopyDestFileType',
  'ccCopyServerAddress', 'ccCopyFileName', 'ccCopyEntryRowStatus',
  'ccCopyState', 'ccCopyFailCause'
);
%EXPORT_TAGS	= (
  ALL		=> [@EXPORT_OK],  
  oids		=> [@EXPORT_OK]  
);

sub new {
###
### -- Create a new CopyConfig object

  my($class)	= shift;				## - Object class
  my($self)	= bless {
    'err'	=> '',					## - Error message
    'host'	=> '',					## - Default host
    'comm'	=> '',					## - Default community
    'tmout'	=> 2,					## - Default timeout
    'retry'	=> 2					## - Default retries
  }, $class;
  $self->_newarg(@_);					## - Parse arguments
  srand(time() ^ ($$ + ($$ << 15)));			## - Seed random number
  $self->{snmp}	= $self->open();			## - Get SNMP object
  $self;
}

sub open {
###
### -- Create SNMP session and return object

  my($self)	= shift;

  $self->_newarg(@_);					## - Parse arguments
  unless(defined($self->{host}) && defined($self->{comm})){
    $self->{err} = 'missing hostname or community string';
    return undef;
  }
  $self->{snmp}	= Net::SNMP->session(			## - Create SNMP object
    Hostname	=> $self->{host},
    Community	=> $self->{comm},
    Timeout	=> $self->{tmout},
    Retries	=> $self->{retry},
    Version	=> 1
  );
}

sub close {
###
### -- Shut down SNMP session and destroy SNMP object

  my($self)	= shift;
  my($snmp)	= $self->{snmp};
  $self->{snmp}	= undef;

  $snmp->close();
}

sub copy {
###
### -- Copy a running-config to a tftp server file

  my($self)	= shift;
  my($addr)	= shift || return undef;
  my($file)	= shift || return undef;
  $self->{rand}	= int(rand(1 << 24));
  unless($self->_cktftp($addr, $file)){
    return undef;
  }
  my(@oids)	= (
    $self->ccCopyProtocol(1),
    $self->ccCopySourceFileType(4),
    $self->ccCopyDestFileType(1),
    $self->ccCopyServerAddress($addr),
    $self->ccCopyFileName($file),
    $self->ccCopyEntryRowStatus(4)
  );
  $self->_xfer(@oids);
}

sub merge {
###
### -- Merge a tftp server file into a running-config

  my($self)	= shift;
  my($addr)	= shift || return undef;
  my($file)	= shift || return undef;
  $self->{rand}	= int(rand(1 << 24));
  unless($self->_cktftp($addr, $file)){
    return undef;
  }
  my(@oids)	= (
    $self->ccCopyProtocol(1),
    $self->ccCopySourceFileType(1),
    $self->ccCopyServerAddress($addr),
    $self->ccCopyFileName($file),
    $self->ccCopyDestFileType(4),
    $self->ccCopyEntryRowStatus(4)
  );
  $self->_xfer(@oids);
}

sub error {
###
### -- Return last error message

  my($self)	= shift;

  print STDERR "$self->{err}\n";

  defined($self->{err}) ? $self->{err} : '' ;
}

sub _newarg {
###
### -- Parse new object arguments

  my($self)	= shift;
  my(%arg)	= @_;

  foreach(keys %arg){
    $self->{host}  = $arg{$_}, next if /^Host$/oi;	## - SNMP host
    $self->{comm}  = $arg{$_}, next if /^Comm$/oi;	## - SNMP community 
    $self->{tmout} = $arg{$_}, next if /^tmout$/oi;	## - SNMP timeout
    $self->{retry} = $arg{$_}, next if /^Retry$/oi;	## - SNMP timeout
  }
}

sub _cktftp {
###
### -- Check tftp arguments

  my($self)	= shift;
  my($addr)	= shift;
  my($file)	= shift;

  if ($addr !~ /^[\d\.]+$/ || !defined(inet_aton($addr))) {
    $self->{err} = 'invalid tftp server address';
    return 0;
  }
  if ($file !~ /^(\/)|([A-Za-z]:)S+/) {
    $self->{err} = 'invalid tftp file name';
    return 0;
  }
  1;
}

sub _xfer {
###
### -- Do actual tftp transfer

  my($self)	= shift;
  my(@oids)	= @_;					## - OIDs to use
  my($snmp)	= $self->{snmp};			## - SNMP obj ref
  my($answer)	= '';					## - SNMP answer
  my($status)	= 0;					## - SNMP xfer status

  $snmp->set_request(@oids);				## - Start xfer
  if ($snmp->error()) {
    $self->{err} = 'initial request failed';
    return 0;
  }
  while($status <= 2){
    $answer	= $snmp->get_request($self->ccCopyState());
    $status	= $answer->{$self->ccCopyState()};
    print STDERR "status: $status\n";
    last if $status == 3;				## Xfer succeeded

    if ($status == 4) {					## Xfer failed
      $answer	= $snmp->get_request($self->ccCopyFailCause());
      $status	= $answer->{$self->ccCopyFailCause()};

      $self->{err}	= 'unknown error'	if $status == 1;
      $self->{err}	= 'file access error'	if $status == 2;
      $self->{err}	= 'tftp timeout'	if $status == 3;
      $self->{err}	= 'out of memory'	if $status == 4;
      $self->{err}	= 'no configuration'	if $status == 5;

      return 0;
    }
    sleep(1);
  }
  $snmp->set_request($self->ccCopyEntryRowStatus(6)); 	## - Clear entry row
  1;
}

### -- OIDs taken from CISCO-CONFIG-COPY-MIB-V1SMI.my
###
sub ccCopyProtocol       {
  my($self)	= shift;
  ('1.3.6.1.4.1.9.9.96.1.1.1.1.2.'  . $self->{rand}, INTEGER, $_[0])
}
sub ccCopySourceFileType {
  my($self)	= shift;
  ('1.3.6.1.4.1.9.9.96.1.1.1.1.3.'  . $self->{rand}, INTEGER, $_[0])
}
sub ccCopyDestFileType   {
  my($self)	= shift;
  ('1.3.6.1.4.1.9.9.96.1.1.1.1.4.'  . $self->{rand}, INTEGER, $_[0])
}
sub ccCopyServerAddress  {
  my($self)	= shift;
  ('1.3.6.1.4.1.9.9.96.1.1.1.1.5.'  . $self->{rand}, IPADDRESS, $_[0])
}
sub ccCopyFileName       {
  my($self)	= shift;
  ('1.3.6.1.4.1.9.9.96.1.1.1.1.6.'  . $self->{rand}, OCTET_STRING, $_[0])
}
sub ccCopyEntryRowStatus {
  my($self)	= shift;
  ('1.3.6.1.4.1.9.9.96.1.1.1.1.14.' . $self->{rand}, INTEGER, $_[0])
}
sub ccCopyState          { 
  my($self)	= shift;
  '1.3.6.1.4.1.9.9.96.1.1.1.1.10.'  . $self->{rand}
}
sub ccCopyFailCause      { 
  my($self)	= shift;
  '1.3.6.1.4.1.9.9.96.1.1.1.1.13.'  . $self->{rand}
}
1;							## - Needed for require

__END__

=head1 NAME

Cisco::CopyConfig - IOS running-config manipulation

=head1 SYNOPSIS

use Cisco::CopyConfig ();

see METHODS section below

=head1 DESCRIPTION

Cisco::CopyConfig provides methods for manipulating the running-config of 
devices running IOS via SNMP directed TFTP.  This module is essentially a 
wrapper for Net::SNMP and the CISCO-CONFIG-COPY-MIB-V1SMI.my MIB schema. 

=head1 PREPERATION

A read-write SNMP community needs to be defined on each device, which allows
the setting of parameters to copy or merge a running-config. Below is an 
example configuration that attempts to restrict read-write access to only the 
10.0.1.3 host:

    access-list 10 permit host 10.0.1.3
    access-list 10 deny any
    !
    snmp-server tftp-server-list 10
    snmp-server view backup ciscoMgmt.96.1.1.1.1 included
    snmp-server community 2dcf0eeca916a5 view backup RW 10
    end

=head1 METHODS

=over 8

=item I<new>

Create a new Cisco::CopyConfig object.

    $config = Cisco::CopyConfig->new(
               Host  => $ios_device_hostname,
               Comm  => $community_string,
            [ Tmout  => $snmp_timeout_in_seconds, ]
            [ Retry  => $snmp_retries_on_failure, ]
    );

=item I<copy>

Copy the running-config to a TFTP server file.  This is
a convenient means of backing up a device configuration.

    $config->copy($tftp_address, $tftp_file);

=item I<merge>

Modify or "merge" the current running config with a TFTP
server file.  This is a conveient means of altering device configuration.

    $config->copy($tftp_address, $tftp_file);

=item I<error>

Return the last error message, if any.  It may be more convenient to 
reference the error variable directly, $config->{err}

    $config->error();

=back

=head1 EXAMPLE

Using 10.0.1.3 as a TFTP server, the following example copies the 
running-config of lab-router-a:

    $tftp_a	= '10.0.1.3';
    $tftp_f	= '/tftpboot/lab-router-a.config';
    $host_a	= 'lab-router-a';
    $comm_s	= '2dcf0eeca916a5';
    $config	= Cisco::CopyConfig->new(
		     Host => $host_a,
		     Comm => $comm_s
    );
    if ($config->copy($tftp_a, $tftp_f)) {
      print "${host_a}:running-config -> ${tftp_a}:${tftp_f}\n";
    }
    else {
      print "$config->{err}\n";
    }

=head1 PREREQUISITES

This module requires the I<Net::SNMP> and I<Socket> modules.  

=head1 BUGS

Local file creation and permissions checking are not performed, as 
TFTP file destinations can be somewhere other than the local system.

Only SNMP v1 and v2 are currently supported in this module.  SNMP v3 
is on the TODO list.

=head1 AUTHORS

Aaron Scarisbrick <aaronsca@cpan.org>

=head1 DISCLAIMER

THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.

=cut

### -- EOF
