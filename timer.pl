#!/usr/local/bin/perl
use strict;
use warnings;
use Time::Local;
use Time::Piece;
use POSIX qw/strftime/;

sub GetSecondsFrom {
	my ($date,$time)=@_;
	my ($mo,$da,$yr)=split("/",$date);
	my ($hr,$mn,$sc)=split(":",$time);
	my $time1 = timelocal( $sc,$mn,$hr,$da,$mo-1, $yr );
	my $date1 = localtime( $time1 );
	return $date1;
}

my $date1=strftime('%m/%d/%Y',localtime);
my $time1=strftime('%H:%M:%S',localtime);
my $date2="03/31/14";
my $time2="21:30:00";

my $d1=GetSecondsFrom($date1, $time1);
my $d2=GetSecondsFrom($date2, $time2);

if( $d2 < $d1 ) {
   print "The date was in the past\n";
   } else {
	my $seconds = ($d2 - $d1);
	while ( $seconds > 0 ) {
		print "Waiting ";
		print "$seconds...\n";
		sleep 1;
		$seconds--;
	}
}	

exit 0;
