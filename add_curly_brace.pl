# perl

use strict;
use warnings;

sub split_comment
{
   my $line = shift @_;
   my $fhandle = shift @_;
   my @line = split //, $line;
   my$llen = scalar @line;
   for(my $I=0; $I < $llen; $I++)
   {
      my $c = $line[$I];

      if('"' eq $c) { $I = gotoend(\@line, $I+1, $fhandle, '"') }
      elsif("'" eq $c) { $I = gotoend(\@line, $I+1, $fhandle, "'") }
      elsif('#' eq $c) { return crop_comment($line, $I) }
      else { } # do nothing

      return () if -1 == $I;
   }
   return ($line, undef);
}

sub crop_comment
{
   my $line;
   my $curr;
   my $comment;

   $line = shift @_;
   $curr = shift @_;

   ($line, $comment) =
    $line =~ /^(.{$curr})(.*)$/;

   return ($line, $comment);
}

sub gotoend
{
   my $c = '';
   my $line = '';

   my @line = @{shift @_};
   my $curr = shift @_;
   my $fhandle = shift @_;
   my $delim = shift @_;

   my $llen = scalar @line;
   my $I = $curr;

   for( ; ; )
   {
      for( ; $I < $llen; $I++)
      {
         $c = $line[$I];
         if('\\' eq $c)
         {
            $I++;
            next;
         }
         elsif($c eq $delim)
         {
            return $I;
         }
         else
         {
            next;
         }
      }
      $line = readline($fhandle);
      return -1 if not $line;
      @line = split //, $line;
      $llen = scalar @line;
      $I=0;
   }
}

sub main
{
   my $fhInp;
   my $fhOut;

   my $level = 0;

   my $args  = '';
   my $line  = '';
   my $ncst  = ''; # statement that is not an code
   my $lcurr = ''; # current level
   my $lprev = ''; # previous level
   my $comment = '';

   my @levelStack = ();

   if(scalar @ARGV < 1)
   {
      print("usage> perl $0 <input_filename>\n");
      exit(1);
   }

   my $ext; # file extension
   my $filename = $ARGV[0];

   ($ext) = $filename =~ /\.(.*)$/;
   # remove file extenstion
   $filename =~ s/\.(.*)$//;

   open $fhInp, "$filename.$ext" or die $!;
   open $fhOut, " > $filename.wcb.$ext" or die $!;

   while($line = readline($fhInp))
   {
      if($line =~ /^\s*$/ or
         $line =~ /^\s*#.*$/) # skip empty lines and comments
      {
         $ncst .= $line;
         next;
      }
      elsif($line =~ /"""/) # skip multi-line comment block
      {
         print $fhOut $line;
         $line =~ s/"""//;
         while($line !~ /"""/)
         {
            $line = readline($fhInp);
            print $fhOut $line;
         }
         next;
      }

      if($line =~ /^\s*def /)
      {
         ($args) = $line =~ /(\([^\)]*\))/;
         $line =~ s/\([^\)]*\)//;
      }

      ($line, $comment) = split_comment($line, $fhInp);

      if($line =~ /\{/) # skip dictionary initialization
      {
         my $ncb = 1; # number of curly braces
         print $fhOut $line;
         $ncb-=1 if $line =~ /\}/;
         while($ncb)
         {
            $line = readline($fhInp);
            if($line =~ /\{/) { $ncb+=1 }
            if($line =~ /\}/) { $ncb-=1 }
            print $fhOut $line;
         }
         next;
      }

      ($lcurr) = $line =~ /^([ \t]*)/; # copy the indentation

      if($lcurr gt $lprev)
      {
         push(@levelStack, $lprev);
         print $fhOut $ncst;
         $ncst = '';
      }
      elsif($lcurr lt $lprev)
      {
         $level = length($lprev)
                - length($lcurr);
         for(my $I=0; $I<$level; $I++)
         {
            $lcurr = pop(@levelStack);
            print $fhOut "$lcurr# }\n";
         }
         print $fhOut $ncst;
         $ncst = '';
      }
      else
      {
         print $fhOut $ncst;
         $ncst = '';
      }

      if($line =~ /^\s*(for|while)[ \(\:]/      or
         $line =~ /^\s*(with|def|class)[ \(\:]/ or
         $line =~ /^\s*(if|elif|else)[ \(\:]/   or
         $line =~ /^\s*(try|except)[ \(\:]/      )
      {
         while($line !~ /:\s*$/)
         {
            print $fhOut $line;
            $line=readline($fhInp);
            ($comment) = $line =~ /#(.*)$/; # copy the comment
            ($line) =~ s/#.*$//; # remove the comment
         }

         $args = $args?$args:'';
         $line =~ s/:\s*$/$args : # {/; # add curly braces
         print $fhOut $line, $comment?$comment:'';
         print $fhOut "\n";
         $args = '';
      }
      else
      {
         print $fhOut $line;
         print $fhOut $ncst;
         $ncst = '';
      }
      $lprev = $lcurr;
   }

   # end of input file reached hence print
   # rest of the indentation from levelStack

   foreach (@levelStack) { print $fhOut "$_# }\n" }

   close($fhInp);
   close($fhOut);
}

main();
