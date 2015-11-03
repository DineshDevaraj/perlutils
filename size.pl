
#
# Author       : D.Dinesh
#                www.techybook.com
#                dinesh@techybook.com
#
# Created      : 03 Nov 2015 - Tue
# Updated      : 03 Nov 2015 - Tue
#
# Description  : Get the size summary of folders and it's contens
#

use strict;
use warnings;

my $loc = '';

if($ARGV[0])
{
   if(-f $ARGV[0])
   {
      $loc = $ARGV[0];
   }
   elsif(-d $ARGV[0])
   {
      chdir $ARGV[0];
   }
   else
   {
      print "Invalid location - $ARGV[0]\n";
      exit;
   }
}

my @size;
my $size;
my $lfnl = 0; # largest file name length
my $total = 0;

my @file = `ls $loc`;
foreach my $file (@file)
{
   $size = 0;
   chomp $file;

   if(-d $file)
   {
      $size = `ls -lrtR $file | perl -ane '\$t+=\$F[4]; END { print \$t }'`;
   }
   $size += (stat $file)[7];
   push(@size, $size);
   $total += $size;

   $lfnl = length($file) if $lfnl < length($file);
}

push(@file, "Total");
push(@size, $total);

my @unit = (" B", "KB", "MB", "GB");

for(my $I = 0; $file[$I]; $I++)
{
   my $J = 0;
   my $rem = 0;
   my $size = $size[$I];
   while(int($rem = $size/1000))
   { $J++; $size = $rem; }
   printf "%-*s   %3d $unit[$J] ($size[$I])\n", $lfnl, $file[$I], int($size);
}
