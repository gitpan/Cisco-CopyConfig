#! /usr/bin/perl

use strict;
    use Socket;
    my $iaddr = inet_aton("127.0.0.1"); # or whatever address
    my $name  = gethostbyaddr($iaddr, AF_INET);
            
    # or going the other way
    my $straddr = inet_ntoa($iaddr);
    
    print $straddr;
    
    
    