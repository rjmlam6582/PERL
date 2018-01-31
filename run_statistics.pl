#!/usr/bin/perl
use POSIX qw(:sys_wait_h);
use warnings;
use Time::HiRes qw( gettimeofday tv_interval );
use English qw' -no_match_vars ';
use Cwd;

require 'common_functions.pl';

local $SIG{__DIE__} = sub {
	my ($message) = "ERROR: $!\n"."@_";
	SendToOutput($LOGFILE,$message,"both");
};

local $SIG{__WARN__} = sub {
	my ($message) = "WARNING: $!\n"."@_";
	SendToOutput($LOGFILE,$message,"both");
};

sub StartStatistics {
	my ($os,$mode,$CLIENT_SERVER,$be_pid,$fe_pid,$be_name,$fe_name)= @_;
	my $arg=q{};
	$be_pid=0;
	$fe_pid=0;
	if ( $mode eq "client" ) {
		if ( $CLIENT_SERVER eq "NO") {
		until ( $be_pid gt 0 ){
			$arg=`$backend`;
			$arg=Trim($arg);
			if ( $arg ne "" ) {
				if ( $os eq "darwin" ) { #MAC
					my @r=split ' ' , $arg;
					$be_pid=$r[1];
					$be_name=$r[$#r];
				} else { #WINDOWS AND LINUX
					my @r=split ' ' , $arg;
					$be_pid=$r[0];
					$be_name=$r[$#r];
					}
				}
			}
		}
		until ( $fe_pid gt 0 ){
			$arg=`$frontend`;
			$arg=Trim($arg);
			if ( $arg ne "" ) {
				if ( $os eq "darwin" ) { #MAC
					my @r=split ' ' , $arg;
					$fe_pid=$r[1];
					$fe_name=$r[7];
				} else { #WINDOWS AND LINUX
					$fe_pid=substr($arg,0,index($arg," "));
					my @r=split ' ' , $arg;
					$fe_name=$r[$#r];
				}
			}
		}
	} else { #SERVER
		until ( $be_pid ne 0 ){
			$arg=`$backend`;
			if ( $arg ne "" ) {
				my @r=split ' ' , $arg;
				if ( $os eq "linux" ) { $be_pid=$r[1];	} else { $be_pid=$r[0]; }
				$be_name=$r[$#r];
			}
		}
	}
	return ($be_pid,$fe_pid,$be_name,$fe_name);
}

sub CheckProcessRunning {
	my ($os,$mode,$process_type,$pid,$process_name)= @_;
	$pid=0;
	my $arg;
	for ( $process_type ) { # argument = "be" or "fe"
		if (/be/) {
			$arg=`$backend`;
			$arg=Trim($arg);
			if ( $arg eq "" ) {
				$pid=0;
				$process_name="EMPTY";
			} else {
				my @r=split ' ' , $arg;
				if ( $mode eq "server" ) {
					if ( $os eq "linux" ) { $pid=$r[1];} else { $pid=$r[0]; }
				} else {
					if ( $os eq "darwin" ) { $pid=$r[1];} else { $pid=$r[0]; }
					$process_name=$r[$#r];
				}
			}
		} elsif (/fe/) {
			if ( $mode eq "client" ) {
				$arg=`$frontend`;
				$arg=Trim($arg);
				if ( $arg eq "" ) {
					$pid=0;
					$process_name="EMPTY";
				} else {
					my @r=split ' ' , $arg;
					if ( $os eq "darwin" ) { $pid=$r[1]; } else { $pid=$r[0]; }
					if ( $os eq "darwin" ) { $process_name=$r[7]; } else { $process_name=$r[$#r]; }
				}
			}
		}
	}
	return ($pid,$process_name);
}

sub CheckIfStillRunning {
	my ($os,$mode,$be_pid,$fe_pid,$be_name,$fe_name)= @_;
	my $arg=q{};
	$be_pid=0;
	$fe_pid=0;
	$arg=`$backend`;
	$arg=Trim($arg);
	if ( $arg ne "" ) {
		my @r=split ' ' , $arg;
		if ( $mode eq "server" ) {
			if ( $os eq "linux" ) { $be_pid=$r[1];} else { $be_pid=$r[0]; }
		} else {
			if ( $os eq "darwin" ) { $be_pid=$r[1];	} else { $be_pid=$r[0]; }
			$be_name=$r[$#r];
		}
	}
	if ( $mode eq "client" ) {
		$arg=`$frontend`;
		$arg=Trim($arg);
		if ( $arg ne "" ) {
			my @r=split ' ' , $arg;
			if ( $os eq "darwin" ) { $fe_pid=$r[1]; } else { $fe_pid=$r[0]; }
			if ( $os eq "darwin" ) { $fe_name=$r[7]; } else { $fe_name=$r[$#r]; }
		}
	}
	return ($be_pid,$fe_pid,$be_name,$fe_name);
}

sub KillSingleProcess {
	my ($os,$pid,$result) = @_;
	my $p;
	for ($os) {
		if (/(linux|aix|solaris)/) { $p = "kill $pid"; }
		elsif (/cygwin/) { $p = "taskkill /pid $pid /f /t"; }
		elsif (/darwin/) { $p = "kill -9 $pid"; }
	}
	my @p_death=`$p` ;
	$result=@p_death;
	return ($pid,$result);
}

# Feed into this program
#  1) $PROCESS_PATH $stats_dir (location of SPSS exe) - there can be no default;
my $stats_path = shift;
$stats_path ||= 'DIE' unless defined $stats_path; # something like "/userhome/Stats/22_Solaris10/bin"

#  2) $PROCESS_NAME $dir_now (dir to go through) - there can be no default;
my $stats_name = shift;
$stats_name ||= 'DIE' unless defined $stats_name; # like "statisticsb"

#  3) $TEMP_DIR
my $dir_now = shift;
$dir_now ||= 'DIE' unless defined $dir_now; # like "/userhome/richardm/syntax/RHEL5/English/"

#  4) runme.sps
my $file_filter = shift;
$file_filter ||=".*.sps" unless defined $file_filter;

#  5) $WAIT_TIME
my $timeout = shift;
$timeout ||= 600 unless defined $timeout; # like 180

#  6) $SLEEP_TIME
my $sleep_time = shift;
$sleep_time ||= 3 unless defined $sleep_time; #small, like 3

#  7) $SPJ
my $SPJ = shift;
$SPJ ||= "no" unless defined $SPJ; # either "no" or "tempdir/runme.spj"

#  8) $connect_string
my $CONNECT_STRING = shift;
$CONNECT_STRING ||= "EMPTY" unless defined $CONNECT_STRING; # either "empty" or a connect string

#  9) $LOGFILE
my $LOGFILE = shift;

# 10) $CLIENT_SERVER
my $CLIENT_SERVER = shift;

# 11) $f
my $running_file = shift;

# 12) $serveroutputfile
my $SERVER_OUTPUT_FILE = shift;

# 13) $serveroptions
my $SERVER_OPTIONS = shift;

# 14) $username
my $USER = shift;

# done reading arguments

my $l=length($dir_now);
if ( substr($dir_now,$l) ne "/" ) { $dir_now=$dir_now."/" ; }

if ( $stats_name eq "NO_P_NAME" || $dir_now eq 'DIE' ) { die; }

my $os = lc($OSNAME);
my $mode="client";
if ( $stats_name =~ "statisticsb" ) { $mode="server"; }

my $kid;
my $time_so_far;

#OSNAME:
#	Windows, "cygwin" (I guess since I use Cygwin);
#	Mac, "darwin";
#	Linux: "linux";		

for ($os) {
	if ( /(linux|aix|solaris)/ ) {
		if ( $mode eq "server" ) {
			$backend="ps -ef | grep '".$stats_name."' | grep ".$USER. " | grep 'sh -c cd'";
			$frontend = "" ; 
		} else {
			$backend="ps -ef | grep '[s]pssengine' | grep ".$USER ;
			$frontend = "ps -ef | grep [S]TATISTICS | grep -v defunct | grep ".$USER ;
		}
	} elsif ( /cygwin/ ) {
		if ( $mode eq "server" ) {
			$backend="ps -aeW | grep '".$stats_name."'" ;
		} else {
			$backend="ps -aeW | grep '[s]pssengine'" ;
			$frontend="ps -aeW | grep '[s]tats.com' | grep -v cygdrive" ;
		}
	} elsif ( /darwin/ ) {
		$backend="ps -ef | grep '[s]pssengine'" ;
		$frontend="ps -ef | grep '[A]pplications.*spssLauncher'" ;
	}
}

$dir_now=RemoveLast("/",$dir_now);

opendir (DIR, $dir_now) or die;
foreach my $file ( sort readdir DIR ) {
	next unless ($file =~ /\.sps$/);
	if ( $file =~ $file_filter ) {
		my $f=$dir_now."/".$file;
		my $start;
		my $end;
		my $be_pid=0;
		my $fe_pid=0;
		my $be_running=0;
		my $fe_running=0;
		my $last_be_pid=0;
		my $last_fe_pid=0;
		my $be_name="NONE";
		my $fe_name="NONE";
		my $process_died="NONE";
		my $pid = fork();
		
		if ( $pid )	{ #parent
			$start = [gettimeofday];
			RETRY:
			$process_died="NO";
			if ( $be_pid eq 0 && $fe_pid eq 0 ) {
				($be_pid, $fe_pid,$be_name,$fe_name) = StartStatistics($os,$mode,$CLIENT_SERVER,$be_pid,$fe_pid,$be_name,$fe_name);
				if ( $CLIENT_SERVER eq "YES" ) { $be_pid = 777 ; }
				$last_be_pid=$be_pid;
				$last_fe_pid=$fe_pid;
			} else {
				#($be_pid,$fe_pid,$be_name,$fe_name) = CheckIfStillRunning ($os,$mode,$be_pid,$fe_pid,$be_name,$fe_name);
				
				($be_pid,$be_name) = CheckProcessRunning ($os,$mode,"be",$be_pid,$be_name);
				($fe_pid,$fe_name) = CheckProcessRunning ($os,$mode,"fe",$fe_pid,$fe_name);
		
				if ( $CLIENT_SERVER eq "YES" ) { $be_pid = 777 ; }
				if ( $be_pid ne $last_be_pid ) { $be_pid = 0 ;} #The backend process has changed
				if ( $fe_pid ne $last_fe_pid ) { $fe_pid = 0 ;} #The frontend process has changed
				# Need to detect whether the backend has gone down while the frontend is still running or if
				# the frontend has gone down while the backend is still running
				# if the last process id was not 0 and the current one is, then that process stopped working
				if ( $last_fe_pid ne 0 && $fe_pid eq 0 ) { $process_died="FE" ;} #The frontend process has stopped running
				if ( $last_be_pid ne 0 && $be_pid eq 0 ) { $process_died="BE" ;} #The backend process has stopped running
				if ( $last_fe_pid ne 0 && $fe_pid eq 0  && $last_be_pid ne 0 && $be_pid eq 0 ) { $process_died="BOTH" ;} #Both have stopped running
			}
			$kid = 0; #waitpid(-1, WNOHANG);
			my $end_msg="NONE";
			if ( $CLIENT_SERVER eq "YES" && $fe_pid eq 0 ) { $be_pid = 0 ; }
			until ( $be_pid eq 0 && $fe_pid eq 0 ) {
				$time_so_far = tv_interval $start, [gettimeofday];
				print "Waiting $time_so_far seconds...\r";
				for ( $process_died ) {
					if (/FE/) {
						if ( $CLIENT_SERVER ne "YES" ) {
							$end_msg="Frontend process died. Killing backend PID (".$be_pid.")";
							SendToOutput($LOGFILE,$end_msg,"both");
							($be_pid,$end_msg) = KillSingleProcess($os,$be_pid);
							SendToOutput($LOGFILE,$end_msg,"both");
							$fe_pid=0;
							goto ENDJOB; }
					elsif (/BE/) {
						$end_msg="Backend process died. Killing frontend PID (".$fe_pid.")";
						SendToOutput($LOGFILE,$end_msg,"both");
						($fe_pid,$end_msg) = KillSingleProcess($os,$be_pid);
						SendToOutput($LOGFILE,$end_msg,"both");
						$be_pid=0;
						goto ENDJOB; }
					}
				}
	
				if ( $time_so_far < $timeout ) { #Still running job as far as I know
					sleep $sleep_time ;
					goto RETRY ;
				} else {
					print "\n"; #Don't print over wait time
					SendToOutput($LOGFILE,"Wait time exceeded.","both");
					if ( $fe_pid ne 0 ) {
						$end_msg="Killing frontend PID (".$fe_pid.")." ;
						SendToOutput($LOGFILE,$end_msg,"both");
						($fe_pid,$end_msg) = KillSingleProcess($os,$fe_pid);
						SendToOutput($LOGFILE,$end_msg,"both");
						$fe_pid=0;
					}
					($be_pid,$be_name) = CheckProcessRunning ($os,$mode,"be",$be_pid,$be_name);
					if ( $be_pid ne 0 ) {
						$end_msg="Killing backend PID (".$be_pid.")." ;
						SendToOutput($LOGFILE,$end_msg,"both");
						($be_pid,$end_msg) = KillSingleProcess($os,$be_pid);
						SendToOutput($LOGFILE,$end_msg,"both");
						$be_pid=0;
					}
					if ( $be_pid eq 0 && $fe_pid eq 0 ) { goto ENDJOB;}
				}
			}
			ENDJOB:
			$end = [gettimeofday];
			$estimate = tv_interval $start, $end;
			SendToOutput($LOGFILE,"Finished in $estimate seconds.","both");
		} else { #child
			SendToOutput($LOGFILE,"\nRunning ".$running_file."...","both");
			my $arg;
			my $q='"';
			my $fswitch;
			my $stats=$stats_path."/".$stats_name;
			if ( $mode eq "server" ) {
				my $opts=q{};
				if ( $SERVER_OUTPUT_FILE eq "NO" ) { $opts="/dev/null";	} else {$opts=$q.$SERVER_OUTPUT_FILE.".txt".$q; }
				for ($os) {
					if ( $stats_name =~ "statisticsb" ) { $fswitch= " -f " ;}
					if ( /(linux|aix|solaris)/ ) {
						if ( $SERVER_OUTPUT_FILE eq "NO_SERVER_OUTPUT_FILE") { $opts=" > /dev/null"; } else {$opts=" >".$q.$SERVER_OUTPUT_FILE.".txt".$q; }
						$arg="cd ".$stats_path.";./".$stats_name.$fswitch.$q.$f.$q." ".$SERVER_OPTIONS.$opts."; cd - >/dev/null";
					} elsif ( /cygwin/ ) {
						$arg=$stats.$fswitch.$q.$f.$q." ".$SERVER_OPTIONS. " > ".$opts;
					}
				}
			} else {
				$fswitch= " -runsyntax " ;
				$CONNECT_STRING =~ s#EMPTY##g;
				for ($os) {
					if ( /darwin/ ) {
						$arg="open -a ".$stats." --args ".$fswitch."'".$f."'";
					} else {
						if ( $SPJ eq "no" ) {
							$arg=$stats." -nologo ".$CONNECT_STRING.$fswitch."'".$f."'";
						} else {
							$arg=$stats." '".$SPJ."' ".$CONNECT_STRING." -production silent";
						}
					}
				}
			}
			
			exec($arg);
			exit 0;
		} # end parent / child
	}
}
close DIR;
