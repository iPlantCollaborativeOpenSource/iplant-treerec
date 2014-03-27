#!/usr/bin/perl
use strict;

=head1 NAME

reconcile_gene_tree.pl

# a script to
#1) use muscle to alignment of amino acid sequences
#2) use treebest to backtranslate the alignments onto amino acids
#3) use treebest to make the best species tree-guided gene trees
#4) use treebest to infer orthologs 
#5) use reconcile for primetv reconciliation

=head1 DEPENDENCIES

=head2 Required Software

=item * muscle

The muscle multiple sequence alignment program.

=item * TreeBeST

TreeBeST is available as source code from
http://treesoft.sourceforge.net/treebest.shtml

=item * reconcile

The reconcile program is part of the PrIMETV package, and is available 
as an executable and in source code format under the download tab at:
http://prime.sbc.su.se/primetv/

=cut

# place for temporary files
use constant TEMP  => '/tmp';
# this will force overwrite of previous files if true.
use constant FORCE => 0;

chdir "$ENV{HOME}/course/clusters";

while (my $infile = <*DNA.fa>) {
  chomp $infile;

  # The name format is gene_species
  # name all of our outfiles based on the core gene name
  (my $core_name = $infile) =~ s/_DNA.fa//; 
  my $AA_raw = "$core_name\_AA.fa";
  my $AA_aln = "$core_name\_AA.mfa";
  my $DNA_raw = "$core_name\_DNA.fa";
  my $DNA_aln = "$core_name\_DNA.mfa";
  my $treebest_tree = "$core_name\_genetree.nhx";
  my $reconcil_tree = "$core_name\_reconciled.nhx";

  # Maybe use > 1 core
  next if -e "$AA_aln" && !FORCE;
  system "touch $AA_aln";

  # Do the MUSCLE alignnment with AA
  system "muscle -in $AA_raw >$AA_aln";  

  # Do the back-translation alignment with treebest, capture STDERR  
  system "treebest backtrans $AA_aln $DNA_raw > $DNA_aln 2>$core_name.stderr";

  # Run treebest to get the best gene tree, capture STDERR
  print STDERR "\nBuilding gene tree with TreeBEST... ";
  system "treebest best -f ../species_tree_treebest.nwk -o $treebest_tree $DNA_aln 2>>$core_name.stderr";
  print STDERR "DONE!\n";

  # Rarely, branch lengths will be in scientific notation, we need floats
  open IN, $treebest_tree or die $!;
  open OUT, ">/tmp/$treebest_tree" or die$!;
  my $mod;
  while (<IN>) {
      chomp;
      if (/(\d+[eE](\+|\-)+\d+)/) {
	  print "Ooops we have scientific notaion here $1\n";
	  my $scientific_notation = $1;
	  my $decimal_notation = sprintf("%.10f", $scientific_notation);
	  s/$scientific_notation/$decimal_notation/;
	  print "Fixed to float $decimal_notation\n";
	  $mod++;
      }
      print OUT $_, "\n";
  }
  if ($mod) {
      system "mv /tmp/$treebest_tree $treebest_tree";
  }
  else {
      unlink "/tmp/$treebest_tree";
  }

  
  # get the orthology/paralogy info from treebest
  print STDERR "\nInferring orthology with TreeBEST... ";
  system "treebest nj -s ../species_tree_treebest.nwk -t dm -vc $treebest_tree $DNA_aln > $core_name.orthologs.txt 2>>$core_name.stderr";
  print STDERR "DONE!\n";

  # prepare a taxon label -> species map for 'reconcile'
  print STDERR "Preparing map file for RECONCILE\n";
  open TREE, $treebest_tree or die $!;
  open MAP, ">$core_name.map" or die $!;
  while(<TREE>) {
    next unless /_/;
    if (/([^\(]+)_([A-Za-z]+)/) {
      print MAP "$1\_$2\t$2\n";
    }
  }

  # now we can run reconcile
  print STDERR "Running RECONCILE... ";
  system "reconcile $treebest_tree ../species_tree.nwk $core_name.map > $reconcil_tree 2>> $core_name.stderr";  
  print STDERR "DONE!\n";

  print STDERR "\nDONE $core_name!\n\n";
} 


