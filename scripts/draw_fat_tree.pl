#!/usr/bin/perl
use strict;

=head1 DEPENDENCIES

=head2 Required Software

=item * primetv

The PrIMETV program is available for download as a binary, or as
source code from the download tab at:
http://prime.sbc.su.se/primetv/

=cut

# A script to draw fat tree with primetv

while (my $reconciled_tree = <*_reconciled.nhx>) {
  (my $fat_tree = $reconciled_tree) =~ s/_reconciled/_fattree/; 
  my $species_tree = "../species_for_primetv.nwk";

  # for a cleaner image get rid of node labels in the reconciled tree
  my $clean_tree = $reconciled_tree . '.tmp';
 
  open IN, $reconciled_tree or die $!;
  open OUT, ">$clean_tree" or die $!;
  while (<IN>) {
      s/\)\w+/\)/g;
      s/_[A-Za-z]+//g;
        print OUT $_;
  }
  close IN;
  close OUT;  
  system "primetv -f gif -p letter  -b 1024x768  -n -m -o  $fat_tree.gif $clean_tree $species_tree";
  unlink $clean_tree;
} 


