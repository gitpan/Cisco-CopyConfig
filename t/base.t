# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Cisco::CopyConfig;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

### -- Test object creation
###
$ref	= Cisco::CopyConfig->new(Host => '127.0.0.1', Comm => 'public');
if (defined($ref) && ref($ref) && defined($ref->{snmp}) && ref($ref->{snmp})) {
  print "ok 2\n";
}
else {
  print "not ok 2\n";
}

### -- Test object destruction
###
ref($ref) && $ref->close();
if (defined($ref->{snmp}) && ref($ref->{snmp})) {
  print "not ok 3\n";
}
else {
  print "ok 3\n";
}
