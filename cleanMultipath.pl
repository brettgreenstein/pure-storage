#!  /usr/bin/perl

# called by python scripts to clean up multipath.conf alias entries.
# it is able to look for specific lines of text and then it deletes
# everything in the {} block
#
# call with cleanMultipath.pl 'line to search for' /path/to/file
# ./cleanMultipath.pl 'logvol02' /etc/multipath.conf 


use warnings;
#use strict;

local $/ = undef;

$filename = $ARGV[1];
$word = $ARGV[0];
open (FH, $filename) or die "$!";
$file = <FH>;
close FH;
#print "here is my file $file";
$_=$file;
open (FH, ">$filename") or die "$!";
$file =~ s/^[^\n]*multipath[^}]*?$word.*?}.*?$//ms;
print FH "$file";
close FH;
