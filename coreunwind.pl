
# 
# Author : D.Dinesh
#          dinesh@techybook.com           
# 
# Note : Script to decode core dump file as follows
#        1. Find the thread crashed using pflags
#        2. Fetch the call flow of crashed thread using pstack
#        3. Demangle the fetched call flow using c++filt
# 

use strict;
use warnings;

if(0 == scalar(@ARGV))
{
	print "Path to the core file missing\n";
	print "usage : perl $0 core_file_path\n";
	exit;
}

my$path = $ARGV[0];
die"Invalid core file path $path\n" if not -f $path;
die"Read permission denied for $path\n" if not -r $path;

# Get thread Id (tid)
my $flag = `pflags $path | ggrep -B 1 SIG`;
my ($tid) = $flag =~ /\/([0-9]+)/;
my $cti; # current thread Id
my $line;
my @stack = `pstack $path`;
my $cmd;
my $head = shift(@stack);
($head, $cmd) = $head =~ /(.*?):(.*)/;
$cmd =~ s/^\s+|\s+$//g;
my @head = split(" ", $head);

my $pid = $head[3];
my $name = $head[1];
while($line = shift(@stack))
{
	last if ($cti) = $line =~ /thread# ([0-9]+)/ and $tid == $cti;
}
open my $pc, "> PstackCallflow.txt" or die $!; # Pstack Callflow

print $pc "File name : $name\n";
print $pc "Process Id : $pid \n";
print $pc "Run Command : $cmd \n";
print $pc "Exit Thread : $tid \n\n";
while($line = shift(@stack))
{
	last if ($cti) = $line =~ /thread# ([0-9]+)/;
	print $pc $line;
}
close $pc;

`c++filt PstackCallflow.txt > .demangleCallflow.swp`;
open my $ds, ".demangleCallflow.swp" or die $!;  # Demangle SwapCallflow
open my $dc, "> DemangleCallflow.txt" or die $!; # Demangle Callflow
while($line= readline($ds))
{
	my ($ad, $fn, $arg) = $line =~
		/\s+([a-fA-F0-9]+)\s+([a-zA-Z0-9_]+)(\((.*?)\))?/;
	if($fn)
	{
		print $dc "$ad $fn";
		print $dc " $arg" if $arg;
		print $dc "\n";
	}
	else { print $dc $line }
}

`rm-f .demangleCallflow.swp`;
close $ds;
close $dc;
