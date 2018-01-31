#!/usr/local/bin/perl
require 'common_functions.pl';
$subtype_file=$ARGV[0];
$filetype=$ARGV[1];
$out=$ARGV[2];
open (IN, "<".$subtype_file) or die "Couldn't open file $subtype_file, $!";
open (OUT, ">",$out);
while (<IN>) {
if ( /QaOutput/ && ! /FILE HANDLE/ ) {
	chomp;
	s#\"##g;
	s#\s*OUTFILE=QaOutput/##g;
	$filename = Trim($_);
	print OUT "$filename\n";
	}
}
close IN;
close OUT;
exit;