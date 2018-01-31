#!/usr/local/bin/perl
# This script	1) reads a settings file that defines various parameters
#				2) optionally makes subtype files
#				3) runs syntax files
#				4) dumps output xml (OXML) into text files#
#				5) diffs output against a baseline
use strict;
use warnings;
use File::Temp qw(tempfile);
use File::stat;
use Time::Local;
#use Time::Piece;
use POSIX qw/strftime/;
#use utf8;
use open ':std', ':encoding(UTF-8)';
require 'common_functions.pl';
require 'subroutines.pl';
require 'file_codes.pl';

################### Initialize a bunch of variables
#my $datestring = strftime "%a %b %e %H:%M:%S %Y", localtime;
my $DELETE_TMP_FILES="YES";
my $QADATA=q{};
my $QATEMP=q{};
my $QALOCAL=q{};
my $QARESULTS=q{};
my $QAOUTPUT=q{};
my $SYNTAX=q{};
my $datestring=q{};
my $FILE_FILTER=".*";
my $iLang=0;
my $iCount=0;
my $START_DATE="TODAY";
my $START_TIME="NOW";
my $SLEEP_TIME=3;
my $EOL="crlf";
my $QASERVER1="in_QADATA";
my $ACTIVE_DATASET_PRINT="yes";
my $NOTES_PRINT="yes";
my $mode="client";
my $PROD_MODE="no";
my $PRECISION="6";
my $THRESHOLD="1E-12";
my @olang_arg="English";
my @locale_arg="English";
my $SYNTAX_INPUT_DIR="none";
my $OMS_FORMAT="OXML";
my $OMS_SELECT_ALL_EXCEPT="";
my $OMS_INSERT="NO";
my $OMS_TYPE=q{};
my $RUN_SUBTYPES="no";
my $SUBTYPE_FILE=q{};
my $SAMPLE_PCT=100;
my $SORT_BY="ID";
my $MAX_RANDOM_GROUPS=200;
my $SEED_VALUE=123456;
my $BOM="NO";
my $WAIT_TIME=600;
my $LOGFILE="no file.txt";
my $IP_PORT="";
my $PASS="";
my $user_def="";
my $USER="";
my $DOMAIN=q{};
my $datetime_string = q{};
my $baselinedir = q{};
my $comparisondir = q{};
my $new_baseline = q{};
my $diffdir = q{};
my $DIFF_SUMMARY_TYPE="htm";
my $TEMP_DIR = q{};
my $PERL_FILTER = q{};
my $summary_file = q{};
my $MOVE_IDENTICAL = q{};
my $jobs = 0;
my $MOVE = 0;
my $print_line = 1;
my $DECIMAL=".";
my $SEV_MAX = 4;
my $REPORT_UNDIFFABLE = "NO" ;
my $DELETE_WORDS = q{};
my $DELETE_LINE = q{};
my $DELETE_FROM_TO=q{};
my $REPLACE=q{};
my $SUBTYPE_FILTER="_EMPTY_";
my $my_diff_ext=q{};
my $QAOUTPUT_ROOT=q{};
my $pathname=q{};
my $HOST_COM=q{};
my $PROCESS_NAME="NO_P_NAME";
my $PROCESS_PATH="NO_P_PATH";
my $SPJ_TEMPLATE=q{};
my $JOBERRFILE=q{};
my $DIFF_EXT=q{};
my $SCRIPT_LOCATION=q{};
my $SYNTAX_OUTPUT_ROOT=q{};
my $DIFF_NEW_BASELINE=q{};
my $DIFF_BASELINE=q{};
my $DIFF_SUMMARY_NAME=q{};
my $DIFF_DIR=q{};
my $QASERVER=q{};
my $TEST_SUITE=q{};
my $PLATFORM=q{};
my $BUILD=q{};
my $DIFF_BASEROOT=q{};
my $max_name_width=0;
my $HEADER="_NO_HEADER_";
my $FOOTER="_NO_FOOTER_";
my $EDITS=q{};
my $CHANGE_SYNTAX_ONLY="NO";
my $SERVER_OUTPUT_FILE="NO";
my $SERVER_OPTIONS="NO";
my $CLIENT_SERVER="NO";
my @result_string = q{};
my @diff_totals = 0 ;
my @delete_words=q{};
my @delete_line=q{};
my @delete_from_to=q{};
my @replace=q{};
my @job_tasks=q{};
my @test_locales=q{};
my @test_langs=q{};
my @edits=q{};
my @wildcards=q{};
my @input_directories=q{};
my @exclude_cmd=q{};
my @include_cmd=q{};
my @old_files=q{};
my $file_sep='/';
my $SORT_SYNTAX="NO";
my $SAVE_SYNTAX="NO";
my $wild=0;
###################
my $SETTINGS_FILE=$ARGV[0];
open (SETTINGS, "<".$SETTINGS_FILE) or die "Error opening settings file named $SETTINGS_FILE.";

my @cmd_array=q{};

foreach my $case(<SETTINGS>) {
	chomp $case;
	for ( $case ) {
		if ( /(<<)(\S+)(>>)/ ) { @wildcards = split /\|/, $2; $wild=1; }
		elsif (/^(\/\/)/) { } # begins with // is ignored; do nothing
		elsif (/^ *$/)    { } # blank or empty is ignored; do nothing
		else { push @cmd_array, $case;}
	}
}

for (my $i = 0; $i < $#cmd_array+1; $i++) {
	my $case=$cmd_array[$i];
	if ( $wild == 1 ) {
		for (my $j = 0; $j < @wildcards; $j++) {
			my @change = split /\=/, $wildcards[$j];
			for ($case) { if ( /\b$change[0]\b/ ) { s/$change[0]/$change[1]/g; }}
		}
    }

	my $x=index($case,"=");
	my $cmd=uc(substr($case,0,$x));
	my $arg=substr($case,$x+1);
	my $i=0;
	
	for ($cmd) {
		if    (/ACTIVE_DATASET_PRINT/) { $ACTIVE_DATASET_PRINT=$arg; }
		elsif (/BOM/) { $BOM=$arg; }
		elsif (/CHANGE_SYNTAX_ONLY/) { $CHANGE_SYNTAX_ONLY=uc($arg); }
		elsif (/CHANGE_SYNTAX/) { @edits = split /\|/, $arg; }
		elsif (/CLIENT_SERVER/) { $CLIENT_SERVER=uc($arg); }
		elsif (/DECIMAL/) { $DECIMAL=$arg; }
		elsif (/DELETE_TMP_FILES/) { $DELETE_TMP_FILES=uc($arg); } #YES or NO
		elsif (/DOMAIN/) { $DOMAIN=$arg; }
		elsif (/EOL/) { $EOL=$arg; }					 # crlf (\r\n) or lf (\n)
		elsif (/EXCLUDE_CMDS/) { my @test = ReturnArray($arg); @exclude_cmd = grep(s/\s*$//g, @test);}
		elsif (/FILE_FILTER/) { $FILE_FILTER=$arg; }
		elsif (/GROUPS/) { $MAX_RANDOM_GROUPS=$arg; }
		elsif (/HEADER/) { $HEADER=$arg; }
		elsif (/INCLUDE_CMDS/) { my @test = ReturnArray($arg); @include_cmd = grep(s/\s*$//g, @test);}
		elsif (/IP_PORT/) { $IP_PORT=$arg; }
		elsif (/LANGUAGES/) { for ($arg) { s/,/ /g; }; my @test=split(' ',$arg); $i=0; foreach my $o(@test) { $olang_arg[$i]=Enclose($o,'"'); $i++; } }
		elsif (/LOCALES/) { for ($arg) { s/,/ /g; }; my @test=split(' ',$arg); $i=0; foreach my $o(@test) { $locale_arg[$i]=Enclose($o,'"'); $i++; } }
		elsif (/LOGFILE/) { if ( $arg ne q{} ) {$LOGFILE=$arg; } }
		elsif (/NOTES_PRINT/) { $NOTES_PRINT=$arg; }
		elsif (/OMS_FORMAT/) { $OMS_FORMAT=uc($arg); }
		elsif (/OMS_INSERT/) { $OMS_INSERT=uc($arg); }
		elsif (/OMS_SELECT_ALL_EXCEPT/) { $OMS_SELECT_ALL_EXCEPT=uc($arg); }
		elsif (/PASSWORD/) { $PASS=$arg; }
		elsif (/PLATFORM/) { $PLATFORM=$arg; }
		elsif (/PRECISION/) { $PRECISION=$arg; }
		elsif (/PROCESS_PATH/) { $PROCESS_PATH=$arg; }
		elsif (/PROCESS_NAME/) { $PROCESS_NAME=$arg; }
		elsif (/PROD_MODE/) { $PROD_MODE=$arg; }
		elsif (/QADATA/) { $QADATA=$arg; }
		elsif (/QATEMP/) { $QATEMP=$arg; }
		elsif (/QALOCAL/) { $QALOCAL=$arg; }
		elsif (/QAOUTPUT_ROOT/) { $QAOUTPUT_ROOT=$arg; }
		elsif (/QARESULTS/) { $QARESULTS=$arg; }
		elsif (/QASERVER/)	{ $QASERVER1=$arg; }
		elsif (/RUN_SUBTYPES/)	{ $RUN_SUBTYPES=uc($arg); }
		elsif (/SAMPLE/) { $SAMPLE_PCT=$arg; }
		elsif (/SCRIPT_DIRECTORY/) { $SCRIPT_LOCATION=$arg; }
		elsif (/SEED/) { $SEED_VALUE=$arg; }
		elsif (/SERVER_OPTIONS/) { $SERVER_OPTIONS=$arg; }
		elsif (/SERVER_OUTPUT_FILE/) { $SERVER_OUTPUT_FILE=uc($arg); } # YES or NO
		elsif (/SLEEP/) { $SLEEP_TIME=$arg; }
		elsif (/SORT_BY/) { $SORT_BY=uc($arg); } # Understands (one of) "ID", "SUBTYPE", "SELECT", or "RANDOM_NUMBER"
		elsif (/SORT_SYNTAX/) { $SORT_SYNTAX=uc($arg) ; }
		elsif (/SPJ_TEMPLATE/) { $SPJ_TEMPLATE=$arg; }
		elsif (/START_DATE/) { $START_DATE = $arg; }
		elsif (/START_TIME/) { $START_TIME = $arg; }
		elsif (/STATS_PATH_FILE/) { $HOST_COM=$arg; }
		elsif (/SUBTYPE_FILE/) { $SUBTYPE_FILE=$arg; }
		elsif (/SUBTYPE_FILTER/) { $SUBTYPE_FILTER=$arg; }
		elsif (/SYNTAX_INPUT/)  { for ($arg) { s/,/ /g; }; my @test=split(' ',$arg); $i=0; foreach my $o(@test) { $input_directories[$i]=$o; $i++; } }
		elsif (/SYNTAX_OUTPUT/) { $SYNTAX_OUTPUT_ROOT=$arg; $SAVE_SYNTAX="YES"; }
		elsif (/TASKS/) { @job_tasks=$arg; }
		elsif (/TEMP_DIR/) { $TEMP_DIR=$arg; }
		elsif (/THRESHOLD/) { $THRESHOLD=$arg; }
		elsif (/USER/) { $USER=$arg; }
		elsif (/WAIT_FOR_FILE/) { $WAIT_TIME=$arg; }
		#DIFFING OPTIONS
		elsif (/BUILD/) { $BUILD=$arg; }
		elsif (/DELETE_FROM_TO/) { $DELETE_FROM_TO=$arg; }
		elsif (/DELETE_LINE/) { $DELETE_LINE=$arg; }
		elsif (/DELETE_WORDS/) { $DELETE_WORDS=$arg; }
		elsif (/DIFF_BASEROOT/) { $DIFF_BASEROOT=$arg; }
		elsif (/DIFF_BASELINE/) { $DIFF_BASELINE=$arg; }
		elsif (/DIFF_DIR/) { $DIFF_DIR=$arg; }
		elsif (/DIFF_EXT/) { $DIFF_EXT=$arg; }
		elsif (/DIFF_NEW_BASELINE/) { $DIFF_NEW_BASELINE=$arg; }
		elsif (/DIFF_SUMMARY_TYPE/) { $DIFF_SUMMARY_TYPE=$arg; } # HTM or TXT
		elsif (/DIFF_SUMMARY_NAME/) { $DIFF_SUMMARY_NAME=$arg; }
		elsif (/MOVE_IDENTICAL/) { $MOVE_IDENTICAL=$arg; }
		elsif (/PLATFORM/) { $PLATFORM=$arg; }
		elsif (/REPLACE/) { $REPLACE=$arg; }
		elsif (/REPORT_UNDIFFABLE/) { $REPORT_UNDIFFABLE = uc($arg); }
		elsif (/SEVERITY/) { $SEV_MAX=$arg; }
		elsif (/SYNTAX_SUMMARY/) { $SYNTAX=$arg; }
		elsif (/TEST_SUITE/) { $TEST_SUITE=$arg; }
	}
}
########

# Take care of setting the input directories
if ( $input_directories[0] ne "" ) {
	my $c=0;
	my $d=0;
	$c++ while ($input_directories[0] =~ m#/#g);
	$d++ while ($input_directories[0] =~ m/\\/g);
	if ( $d > $c ) { $file_sep='\\'; }
}
@input_directories=MakeDirs(\@input_directories);
########

#### Begin when scheduled
WaitForJobToBegin($START_DATE,$START_TIME);

my $log_path= GetPathFromFileName ($LOGFILE, $TEMP_DIR );

if ( ! -d $log_path) { #dir exists
	mkdir $log_path; # Create the log file dir if it does not exist
};

open(my $fh, '>', $LOGFILE) or die "Could not open file '$LOGFILE' $!";
print $fh "";
close $fh;

for ($OMS_FORMAT) {
	if (/OXML/) { $OMS_TYPE=".xml"; }
	elsif (/HTML/) { $OMS_TYPE=".htm"; }
	elsif (/TEXT/) { $OMS_TYPE=".txt"; }
	elsif (/TABTEXT/) { $OMS_TYPE=".prn"; }
	elsif (/PDF/) { $OMS_TYPE=".pdf"; }
	elsif (/XLS/) { $OMS_TYPE=".xls"; }
	elsif (/XLSX/) { $OMS_TYPE=".xlsx"; }
	elsif (/DOC/) { $OMS_TYPE=".doc"; }
	elsif (/SPV/) { $OMS_TYPE=".spv"; }
	elsif (/REPORTHTML/) { $OMS_TYPE=".htm"; }
	elsif (/REPORTMHT/) { $OMS_TYPE=".mht"; }
}

# Run begins
my $task=0;
foreach my $t(@job_tasks) {
	my $x=uc($t);
	for ($x) {
		if (/MAKE/) { $task=1; } 
		if (/RUN/) { $task=$task+2; }
		if (/DMP/) { $task=$task+4; }
		if (/DIFF/) { $task=$task+8; }
	}
}

my $y=q{};
if    ($task == 1)  { $y="Make subtype files only." ; }
elsif ($task == 2)  { $y="Run already created files." ; }
elsif ($task == 3)  { $y="Make subtype files and run them."  ; }
elsif ($task == 4)  { $y="Create TXT and DMP files only."  ; }
elsif ($task == 5)  { $y="Make subtype files and create TXT and DMP files."  ; }
elsif ($task == 6)  { $y="Run files and create TXT and DMP files."  ; }
elsif ($task == 7)  { $y="Make subtype files, run them, and create TXT and DMP files."  ; }
elsif ($task == 8)  { $y="Diff already created output files" ; }
elsif ($task == 9)  { $y="Make subtype files and diff already created output files" ; }
elsif ($task == 10) { $y="Run files and diff" ; }
elsif ($task == 11) { $y="Make subtype files, run, and diff" ; }
elsif ($task == 12) { $y="Create TXT/DMP files, and diff" ; }
elsif ($task == 13) { $y="Make subtype files, create TXT/DMP files, and diff" ; }
elsif ($task == 14) { $y="Run files, create TXT/DMP files, and diff" ; }
elsif ($task == 15) { $y="Make subtype files, run them, create TXT/DMP files, and diff" ; }

SendToOutput($LOGFILE,$y,"both");

my $MakeOutput="False";
my $UsingSubtypes=0;
my $RunningButNotSubtypes=0;
my $CreatingFiles="False";
my $DiffFiles="False";
my $RunSyntax="False";
my $MakeDMPFiles="False";
if ( $task == 4 || $task == 5 || $task == 6 || $task == 7 || $task >= 12 ) { $MakeOutput="True"; }
if ( $task == 2 || $task == 3 || $task == 6 || $task == 7 || $task == 10 || $task == 11 || $task >= 14 ) { $RunSyntax="True"; }
if ( $task == 1 || $task == 3 || $task == 5 || $task == 7 || $task == 9 || $task == 11 || $task == 13 || $task == 15 ) { $CreatingFiles="True"; }
if ( $task == 4 || $task == 5 || $task == 6 || $task == 7 ||$task >= 12 || $task == 13 || $task == 14 || $task == 15 ) { $MakeDMPFiles="True"; }
if ( $task >= 8 ) { $DiffFiles="True"; }

$UsingSubtypes =  $task % 2; # This is 1 if subtype file is needed. If you don't find $SUBTYPE_FILE, quit with an error.

if ( $QAOUTPUT_ROOT eq "" ) { die "Cannot continue; need output path for file creation (QAOUTPUT_ROOT).\n"; }
if ( $SORT_BY =~ "RAN" ) { $SORT_BY="RANDOM_NUMBER"; }
if ( $MAX_RANDOM_GROUPS eq q{} ) { $MAX_RANDOM_GROUPS = 0; }

if ( $DiffFiles eq "True" ) { # BEGIN DIFF OPTIONS (IF DIFFING)
	if ( $FILE_FILTER ne ".*" ) { $PERL_FILTER=$FILE_FILTER.".".$DIFF_EXT ;} else { $PERL_FILTER=".".$DIFF_EXT ; }
	if ( -e $SYNTAX ) { } else {
		$pathname=GetPathFromFileName($SYNTAX,$TEMP_DIR);
		if ( -e $pathname ) { } else { mkdir $pathname; }
	}
	
	open ( SYNTAX, ">", $SYNTAX ) or die "Error on syntax argument ( $SYNTAX ): $!.\n" ;
	print SYNTAX "DATA LIST FREE /BUILD (A12) PLATFORM (A12) TEST_CASE (A120) TEST_SUITE (A12) TEST_RESULT (A12) TEST_DATE (A32) LANGUAGE (A12).\n";
	print SYNTAX "BEGIN DATA.\n";
	$my_diff_ext=".".$DIFF_EXT;
} # END DIFF OPTIONS

#Start with an empty log (means: kill whatever file exists with that name)

if ( -e $LOGFILE ) { unlink $LOGFILE ;}
if ( $LOGFILE eq "no file.txt" ) { $LOGFILE = tempfile( ); }

#my $datestring = POSIX::strftime "%a %b %e %H:%M:%S %Y", localtime;
$datestring = localtime();
SendToOutput($LOGFILE,"Job begun: ".$datestring,"log");

my $timer_file=MakeFileName($SCRIPT_LOCATION,'timer.bsh');

my $elnum=scalar @olang_arg;

if ( $elnum == 1 ) {
	$y = uc($olang_arg[0]);
	if ( $y =~ "ALL" ) {
		@test_langs=qw(BPortugu English French German Italian Japanese Korean Polish Russian SChinese Spanish TChinese);
	} else { @test_langs=@olang_arg; }
} else {
	@test_langs=@olang_arg;
}

if ( scalar @locale_arg == 1 ) {
	$y = uc($locale_arg[0]);
	if ( $y =~ "ALL" ) {
		@test_locales=qw(Spanish English French German Italian Japanese Korean Polish Russian SChinese Spanish TChinese);
	} else { @test_locales=@locale_arg; }
} else {
	@test_locales=@locale_arg;
}

for ($QADATA) { s#\\#/#g; s#\"##g; }
for ($QATEMP) { s#\\#/#g; s#\"##g; }
for ($QALOCAL) { s#\\#/#g; s#\"##g; }
for ($TEMP_DIR) { s#\\#/#g; s#\"##g; }

if ( $UsingSubtypes ) {
	$RunningButNotSubtypes=0;
	if ( -e $SUBTYPE_FILE ) { #file exists
		my $x=$SUBTYPE_FILE;
		$SUBTYPE_FILE=MakeFileName($SCRIPT_LOCATION,$x);
	} else {
		die "Cannot find subtype file. Please check the existence and location of the file $SUBTYPE_FILE.";
	}	
} else {
	if ( $task == 2 || $task == 6 || $task == 10 || $task == 14 ) { $RunningButNotSubtypes=1; }
}

my $LANG_SCRIPT=MakeFileName($SCRIPT_LOCATION,"make_group.pl");

$iLang=0;
my $bLangNeeded=1;
foreach my $test_langs(@test_langs) {
	@result_string = q{};
	@diff_totals = 0 ;
	my $i=0 ;
	for ($i = 0; $i <= $SEV_MAX; $i++) { $diff_totals[$i] = 0; }
	my $OLANG=Remove($test_langs[$iLang],"\"");
	my $LOCALE=Remove($test_locales[$iLang],"\"");
	my $LANGSHORT=get_lang($OLANG);
		
	if ( $LANGSHORT eq "NONE" ) {
		print "Language not necessary for this run.\n";
		if ( $QAOUTPUT_ROOT eq "%QAOUTPUT%" ) { $QAOUTPUT="%QAOUTPUT%"; } else { $QAOUTPUT=$QAOUTPUT_ROOT ; }
	} else {
		print "Running $OLANG language.\n";
		if ( $QAOUTPUT_ROOT eq "%QAOUTPUT%" ) { $QAOUTPUT="%QAOUTPUT%"; } else { $QAOUTPUT=MakeFileName($QAOUTPUT_ROOT,$LANGSHORT); }
	}

	mkdir($QAOUTPUT) unless(-d $QAOUTPUT);
		
	$iLang++;
	if ( $OLANG eq "BPortuguese" ) { $OLANG="BPortugu"; }
	
	for ($QASERVER1) {
		if (/%%QASERVER%%/) { $QASERVER=$QASERVER1; }
		elsif (/in_QADATA/)	{ 
			if ( $LANGSHORT eq "NONE" ) {
				$QASERVER="QaData/languages/English"; # I don't know what else to guess...
			} else {
				$QASERVER=MakeFileName("QaData/languages",$OLANG);
			}
		}
		else { $QASERVER=$QASERVER1; }
	}
	
	if ( $CreatingFiles eq "True" ) { # FILE CREATION FOR ALL LANGUAGES
		$SYNTAX_INPUT_DIR=MakeFileName($SYNTAX_OUTPUT_ROOT,$OLANG);		
		# This script needs the variables OLANG, LOCALE, QADATA, QATEMP, QAOUTPUT, QASERVER, QALOCAL,
		# a (language?) specific output directory, the name of the subtype file, how to sort the testcases, a maximum number for randomly
		# generated files ($sort_by = "RANDOM_NUMBER"), and a seed value for the random numbers.
		my $ff=Enclose($SUBTYPE_FILTER,'"');
		system("perl $LANG_SCRIPT $OLANG $LOCALE $QADATA $QATEMP $QALOCAL $QASERVER $QAOUTPUT $SYNTAX_INPUT_DIR $SETTINGS_FILE $ff");
		wait;
	}

	# RESET THE DIFF STATISTICS ARRAYS
	if ( $DiffFiles eq "True" ) {
		if ( $MOVE == 1 ) { open( MOVE_FILES, ">", $MOVE_IDENTICAL ); }
		if ( $DIFF_BASEROOT ne q{} ) {
			if ( $LANGSHORT eq "NONE" ) { $LANGSHORT = "en"; }
			$baselinedir=MakeFileName($DIFF_BASEROOT,$LANGSHORT);
		} else {
			$baselinedir=$DIFF_BASELINE;
		}

		if ( $LANGSHORT eq "NONE" ) {
			$diffdir=MakeFileName($DIFF_DIR);
			$summary_file=MakeFileName($DIFF_DIR,$DIFF_SUMMARY_NAME.".".$DIFF_SUMMARY_TYPE);
		} else {
			$diffdir=MakeFileName($DIFF_DIR,$LANGSHORT);
			$summary_file=MakeFileName($DIFF_DIR,$DIFF_SUMMARY_NAME."_".$LANGSHORT.".".$DIFF_SUMMARY_TYPE);
		}

		#Make diffdir if necessary
		if (-d $diffdir) {} else { system("mkdir -p $diffdir"); }

		if ( $QARESULTS ne "" ) {
			$comparisondir=$QARESULTS; #This is where the comparison files are if QARESULTS (bvt) is being used
		} else {
			$comparisondir=$QAOUTPUT; #Otherwise
		}
		SendToOutput($LOGFILE, "Diffing using baseline directory $baselinedir and comparison directory $comparisondir.\n","log");

		if ( $MOVE_IDENTICAL ne '' ) {
			if (-d $MOVE_IDENTICAL) {} else { system("mkdir -p $MOVE_IDENTICAL"); }
			$MOVE = 1;
			if ( $LANGSHORT eq "NONE" ) {
				$new_baseline=$DIFF_NEW_BASELINE;
			} else {
				$new_baseline=$DIFF_NEW_BASELINE.$file_sep.$LANGSHORT;
			}
			if ( $new_baseline eq $file_sep ) { $new_baseline = $baselinedir ;}
		}
	}

	# RUN SYNTAX (WHICH CREATES THE XML FILES) and/or diff the output
	my @files=q{};
	my $target_extension=q{};
	my $SYNTAX_OUTPUT_DIR=q{};
	my $FIND_FILES=q{};

	if ( $RunSyntax eq "True" ) {
		if ( uc($RUN_SUBTYPES) eq "NO" ) { $SYNTAX_OUTPUT_DIR=$SYNTAX_OUTPUT_ROOT; } else { $SYNTAX_OUTPUT_DIR=MakeFileName($SYNTAX_OUTPUT_ROOT, $OLANG); }
		if ( $SYNTAX_OUTPUT_DIR eq q{} ) { $SYNTAX_OUTPUT_DIR = $TEMP_DIR ; } #NEED TO WRITE SOMEWHERE		
		$FIND_FILES=MakeFileName($SCRIPT_LOCATION,"find_files_to_dmp.pl");
		if ( $LANGSHORT eq "NONE" ) {
			SendToOutput($LOGFILE,"Running syntax jobs.","both");
			CheckDir($QAOUTPUT_ROOT) ;
		} else {
			SendToOutput($LOGFILE,"Running syntax jobs for: $OLANG, Locale: $LOCALE.","both");
			CheckDir($QAOUTPUT_ROOT.$file_sep.$LANGSHORT) ;
		}
		CheckDir($SYNTAX_OUTPUT_DIR) ;
		$iCount=0;
		$target_extension="sps";
		if ( $UsingSubtypes == 0 ) { $SYNTAX_INPUT_DIR=$input_directories[0]; }
		if ( $RunningButNotSubtypes == 0 ) { opendir(TARGETDIR, $SYNTAX_INPUT_DIR) or die "Problem opening syntax input directory $SYNTAX_INPUT_DIR.\n" ; }
	} else { # not running syntax
		if ( $MakeDMPFiles eq "True" ) {
			# You probably can't open this if it's on a server and you're running client/server.
			opendir(TARGETDIR, $QAOUTPUT ) or die "Problem opening QAOUTPUT directory $QAOUTPUT.\n";
			$target_extension="xml";
		} elsif ( $DiffFiles eq "True" ) {
			opendir(TARGETDIR, $baselinedir ) or die "Problem opening baseline directory $baselinedir.\n";
			$target_extension=$DIFF_EXT;
		}
	}

	if ( $task == 1 ) { goto NextLanguage ;} # If just making subtype files, then go to next language.
	
	my $compdir=q{};
	if ( $QARESULTS ne "" ) { $compdir=$QARESULTS; } else { $compdir=$QAOUTPUT; } #The comparison may be using QARESULTS (e.g., bvt)
	my $diff_job=0;

	#GET THE LIST OF FILES
	if ( $RunningButNotSubtypes == 1 ) {
		my @dir_files=q{};
		my $d=q{};
		foreach $d(@input_directories) {
			$d =~ s/^\s+|\s+$//g; #trim leading or trailing spaces
			opendir(TARGETDIR, $d ) or die "Problem opening directory named $d.\n$!";
			@dir_files = grep { (!/^\./) && ( /$FILE_FILTER/ && /$target_extension/i) } readdir(TARGETDIR);
			closedir(TARGETDIR);
			my $fl=q{};
			my $f=q{};
			foreach $fl(@dir_files) {
				$f=$d.'/'.$fl ;
				if ( ( -e $f ) && ( ! -d $f ) && ( $fl ne "" ) ) { push (@files, $f); }
			}
		}
		$target_extension="sps";
	} else {
		if ( $task == 8 || $task == 9 ) { #diffing only
			opendir(TARGETDIR, $QAOUTPUT ) or die "Problem opening directory named $QAOUTPUT.\n$!";
		}
		@files = grep { (!/^\./) && ( /$FILE_FILTER/ && /$target_extension/i) } readdir(TARGETDIR);
		closedir(TARGETDIR);
	}
	if ( $SORT_SYNTAX eq "YES" ) { @files = sort {$a cmp $b} @files; }

	$i=0;
	my @f;
	my $f;
	my @new_array;

	foreach $f(@files) {
		my $r=0;
		$r = 1+int(rand(100)); #SELECT A SAMPLE CASE IF THAT'S WHAT WAS REQUESTED (BY DEFAULT, TAKE EVERY FILE/CASE)
		if ( $r <= $SAMPLE_PCT ) {
			my $name=$f;
			#$name =~ s{.*/}{};      # removes path  
			#$name =~ s{\.[^.]+$}{}; # removes extension
			if ( $name ne "" ) { push (@new_array, $name); }
		}
	}
	@files=@new_array;
	undef @new_array;

	my $include_exclude=0;
	if ($#include_cmd > 0 || $#exclude_cmd > 0) { $include_exclude=1; }

	#START LOOPING THROUGH FILES
	my $N = 0;
	#First, get list of files in already in temp directory
	@old_files = get_sorted_files($QATEMP);

	foreach my $file(@files) {
		my $TEMPFILE=q{};
		my $dir=q{};
		my $ROOT=q{};
		my $test_job=q{};
		my $dot=rindex($file, ".") ;
		my $path_end=rindex($file, $file_sep) ;
		my $file_extension=substr($file,$dot);
		if ( $path_end == -1 ) { #there is no directory
			$ROOT = substr($file,0,$dot) ;
		} else {
			my $len=0;
			$dir = substr($file,0,$path_end) ;
			$len=rindex($file,".")-($path_end+1);
			$ROOT = substr($file,$path_end+1,$len) ;
		}

		for ($file) { s{.*/}{} } #strips path

		$test_job=$ROOT.$file_extension ;
		if ( $ROOT ne "" ) {
			if ( $RunSyntax eq "True" ) {
				my $SPJ=q{};
				my $TXT=q{};
				my $OMS_EXCEPTIF=q{};
				my $changed_syntax=q{};
				$TEMPFILE=MakeFileName($TEMP_DIR,"runme.sps");
				if (-f $TEMPFILE) { unlink $TEMPFILE; }
				if ( $dir ne "" ) { $SYNTAX_INPUT_DIR=$dir;	}
				open (IN,"<:utf8",$SYNTAX_INPUT_DIR.$file_sep.$test_job) or die $! ; #"There is no such file $SYNTAX_INPUT_DIR."/".$file.\n";
				my $syntax = do { local $/; <IN> }; # slurp!
				utf8::encode($syntax);  # "\x{100}"  becomes "\xc4\x80"
 				utf8::decode($syntax);  # "\xc4\x80" becomes "\x{100}"
				close IN;

				my $keep=1;
				my $drop=0;

				if ( $include_exclude == 0 ) {
					$keep=1;
					$drop=0;
				} else {
					### Check to see if this file should be kept or dropped based on inclusion/exclusion of commands
					($keep,$drop)=ExtractFromSyntax($syntax,$LOGFILE,\@include_cmd,\@exclude_cmd);
					if ( $drop == 1 || $keep == 0 ) {
						SendToOutput($LOGFILE,"Skipped ".$test_job,"both");
						goto NextFile;
					}
				}

				###

				my $pathfile=MakeFileName($SYNTAX_OUTPUT_DIR,$test_job);
				my $p='"'.$pathfile.'"';
				if ( $RunningButNotSubtypes == 1 ) { # running but not subtype files
					if ( uc($NOTES_PRINT) eq "NO" ) { $OMS_EXCEPTIF=" /EXCEPTIF SUBTYPES=[\"Notes\"]"; } else { $OMS_EXCEPTIF=q{} ; }
					# this file could go into an array so that I know later what I created: "QaOutput/$ROOT"$OMS_TYPE"
					open TMP,">:encoding(UTF-8)",$TEMPFILE or warn $!;
					$changed_syntax=MakeGlobalEdits($syntax, $HEADER, $QADATA, $QALOCAL, $QAOUTPUT, $QASERVER, $QATEMP, $QARESULTS, @edits);
					if ( uc($OMS_INSERT) eq "YES" ) {
						my $SELECT="SELECT ALL";
						if ( $OMS_SELECT_ALL_EXCEPT ne "" ) { $SELECT = "SELECT ALL EXCEPT=[".$OMS_SELECT_ALL_EXCEPT."]" ; }
						my $OMS_COMMAND="OMS /".$SELECT." /DESTINATION FORMAT=".$OMS_FORMAT." OUTFILE=\"QaOutput/".$ROOT.$OMS_TYPE."\"".$OMS_EXCEPTIF." /TAG=\"_Test\".";
						my $f;
						if ( $LANGSHORT eq "NONE" ) {
							$f=Enclose($QAOUTPUT_ROOT,'"');
						} else {
							$f=Enclose($QAOUTPUT_ROOT.$file_sep.$LANGSHORT,'"');
						}
						print TMP "\x{FEFF}set printback none.\nFILE HANDLE QaOutput /NAME=".$f.".\n".$OMS_COMMAND."\n".$changed_syntax."\nOMSEND.";
					} else {
						print TMP "\x{FEFF}".$changed_syntax;
					}
					close TMP;
					system("cp $TEMPFILE $p");
				} else { #running subtype files
					if ( $task == 2 ) { #only running; syntax is unchanged
						open TMP,">:encoding(UTF-8)",$TEMPFILE or warn;
						$changed_syntax=MakeGlobalEdits($syntax, $HEADER, $QADATA, $QALOCAL, $QAOUTPUT, $QASERVER, $QATEMP, $QARESULTS, @edits);
						print TMP $changed_syntax;
						close TMP;
					} else {
						system("rm -f $TEMPFILE");
						my $p=$SYNTAX_INPUT_DIR.$file_sep.$test_job;
						system("cp -p '$p' $TEMPFILE");
					}
					if ( $MakeOutput eq "True" ) {
						# Find all the instances where you're writing out from OMS (i.e., search and save out all file references that use QaOutput)
						my $MYFILES=MakeFileName($TEMP_DIR,"files");
						system("perl $FIND_FILES $TEMPFILE $OMS_TYPE $MYFILES");
					}
				}

				if ( $PROCESS_NAME eq "statisticsb" ) { #cannot use production facility
					$mode="server";
					$PROD_MODE = "NO";
				} elsif ( uc($PROD_MODE) eq "YES" ) {
					$mode="production_facility";
					$SPJ=MakeFileName($TEMP_DIR,"runme.spj");
					$TXT=MakeFileName($TEMP_DIR,"runme.txt");
					$JOBERRFILE=MakeFileName($TEMP_DIR,"job_errors.txt");
				} else {
					$mode="client";
					$SPJ="no";
					$JOBERRFILE=MakeFileName($TEMP_DIR,$ROOT."_err.txt");
				}

				my $r = $SYNTAX_INPUT_DIR.$file_sep.$test_job;
				print "Now on: ".$r.". ";
				my $f=Enclose($test_job,'"');
				my $connect_string="EMPTY";
				if ( $CHANGE_SYNTAX_ONLY eq "NO" ) { #This is the default; only changed when CHANGE_SYNTAX_ONLY=YES above
					if ( uc($PROD_MODE) eq "YES" ) {
						open (SPJ_IN, "<".$SPJ_TEMPLATE) or die "Error opening Production Facility template file $SPJ_TEMPLATE.";
						open (SPJ_OUT, ">",$SPJ) or die "Error opening temp file for Production Facility $SPJ.";
						$r = $TEMPFILE; #In PF, we need to run the temp file, not the file $r...
						foreach my $case(<SPJ_IN>) {
							my $x = $case;
							chomp $x;
							$x =~ s#TXT_OUTFILE_HERE#$TXT#g;
							$x =~ s#SPS_FILE_HERE#$r#g;
							print SPJ_OUT $x;
						}
						close SPJ_IN;
						close SPJ_OUT;
					} else {
						$SPJ="no";
						$TXT="no";
					}

					if ( $USER ne "" & $PASS ne "" & $IP_PORT ne "" ) {
						if ( $DOMAIN ne "" ) {
							$user_def=join('\\\\',$DOMAIN,$USER);
						} else {
							$user_def=$USER ;
						}
						$connect_string="'-server ".$IP_PORT." -user ".$user_def." -password ".$PASS."'";
					} else {
						$connect_string="EMPTY";
					}

					my $serveroutputfile=q{};
					my $serveroptions=q{};
					my $username=q{};
					if ( $SERVER_OUTPUT_FILE eq "YES" ) {
						$serveroutputfile = "'".$QAOUTPUT."/".$ROOT."'" ;
					} else {
						$serveroutputfile = "NO_SERVER_OUTPUT_FILE";
					}					
					$serveroptions="'".$SERVER_OPTIONS."'" ;
					if ( $USER ne "" ) { $username = $USER; } else { $username = "NONE"; }
					#print "\n$PROCESS_PATH\n$PROCESS_NAME\n$TEMP_DIR\nrunme.sps\n$WAIT_TIME\n$SLEEP_TIME\n$SPJ\n$connect_string\n$LOGFILE\nclient-server=$CLIENT_SERVER\nfile=$f\nserver output file=$serveroutputfile\nserver options=$serveroptions\nuser name=$username\n";
					
					system("perl run_statistics.pl $PROCESS_PATH $PROCESS_NAME $TEMP_DIR runme.sps $WAIT_TIME $SLEEP_TIME $SPJ $connect_string $LOGFILE $CLIENT_SERVER $f $serveroutputfile $serveroptions $username");
				
					my $busy="YES";
					until ( $busy eq "NO" ) {
						if (open my $tf, "+<", $TEMPFILE) {
							close $tf;
							$busy="NO";
						} else {
							print $^E == 0x20 ? "in use by another process\n" : "$!\n";
							sleep $SLEEP_TIME;
						}
					}
					if ( $SPJ ne "no" ) { unlink $SPJ, $TXT }
					
				} else {
					print "\n";	#Need a new line in the console window...
				}
				
				$N=0;
				my $tf=$TEMP_DIR.$file_sep."runme.sps";
				if (-f $TEMPFILE ) { unlink $TEMPFILE; }
				if ( -f $tf ) { unlink $tf; }
					
				if ( $DELETE_TMP_FILES eq "YES" ) {
					my @new_files = get_sorted_files($QATEMP);					
					my %count;
					for my $element (@old_files, @new_files) { $count{$element}++ }
						my ( @union, @intersection, @difference );
						for my $element (keys %count) {
   						push @union, $element;
    					push @{ $count{$element} > 1 ? \@intersection : \@difference }, $element;
					}
					foreach my $u(@difference) {
						my $del=q{};
						if ( -d $u ) { rmdir $u; $del="Directory "; }
						else { unlink $u; $del="File "; }
						SendToOutput($LOGFILE,$del.$u." deleted.","both");
					}
				}
				
			} #FINISHED RUNNING A SYNTAX JOB
		}

		if ( $MakeOutput eq "True" ) {
			my @xml_files=q{};
			my $sev=q{};
			if ($RunSyntax eq "True" ) {
				opendir(XML_DMP, $QAOUTPUT) or die "Problem opening XML output directory $QAOUTPUT.\n" ;
				my $flt=q{};
				if ( $RunningButNotSubtypes == 1 ) {
					$flt=$ROOT; #was $FILE_FILTER, but this gets every file when filter is empty (i.e., not used)
				} else {
					if ( $ROOT =~ /\s/ ) {
						$flt = $ROOT;
						my $sp='\\s';
						$flt =~ s/ /$sp/g;
					} else {
						$flt=$ROOT;
					}
				}
				if ( $RunningButNotSubtypes == 0 ) {
					@xml_files = grep { /^$flt/ && /\.xml$/i } readdir(XML_DMP); # This allows pattern matching
				} else {
					@xml_files = grep { /^$flt\.xml$/i } readdir(XML_DMP); # An exact (whole word) match
				}
				
				print "Found ".scalar @xml_files." that matched $flt\n";
				closedir XML_DMP;

				foreach my $c(@xml_files) {
					MakeDMPTXT ($c, $QADATA, $QALOCAL, $QAOUTPUT, $QASERVER, $QATEMP, $LOGFILE, $SCRIPT_LOCATION, $TEMP_DIR, $PRECISION, $THRESHOLD, $NOTES_PRINT, $ACTIVE_DATASET_PRINT, $DECIMAL);
					if ( $DiffFiles eq "True" ) {
						$diff_job++;
						chomp $c;
						$ROOT=$c;
						$ROOT=~s/\.xml$//i;
						$result_string[$diff_job]=Diff($ROOT,$my_diff_ext,$baselinedir,$comparisondir,$TEMP_DIR,$diffdir,$new_baseline,$max_name_width,$MOVE,$print_line,$LANGSHORT,$compdir,$OLANG,$BUILD,$PLATFORM,$TEST_SUITE,$DELETE_WORDS,$DELETE_LINE,$REPLACE,$DELETE_FROM_TO);
						#returned is a string with these variables: $sev, $root, $result, $n_not_ignore;
						my @junk = split /:/, $result_string[$diff_job];
						if ( $junk[3] eq "?" ) { $sev=0; } else { $sev=$junk[0]; }
						$diff_totals[$sev]++ ;
					} #diffing file
				} # foreach $c
			} else {
				MakeDMPTXT ($file, $QADATA, $QALOCAL, $QAOUTPUT, $QASERVER, $QATEMP, $LOGFILE, $SCRIPT_LOCATION, $TEMP_DIR, $PRECISION, $THRESHOLD, $NOTES_PRINT, $ACTIVE_DATASET_PRINT, $DECIMAL);
			} #end making DMP and TXT files for this command ID
		} else {
			if ( $DiffFiles eq "True" ) {
				$diff_job++;
				my $sev=q{};
				if ($RunSyntax eq "True" ) {
					chomp $file;
					$ROOT=$file;
					$ROOT=~s/\.sps$//i;
				} else {
					$ROOT=$file;
					$ROOT=~s/[\.xml]$|$my_diff_ext$//i;
				}

				$result_string[$diff_job]=Diff($ROOT,$my_diff_ext,$baselinedir,$comparisondir,$TEMP_DIR,$diffdir,$new_baseline,$max_name_width,$MOVE,$print_line,$LANGSHORT,$compdir,$OLANG,$BUILD,$PLATFORM,$TEST_SUITE,$DELETE_WORDS,$DELETE_LINE,$REPLACE,$DELETE_FROM_TO);
				#returned is a string with these variables: $sev, $root, $result, $n_not_ignore;
				my @junk = split /:/, $result_string[$diff_job];
				if ( $junk[3] eq "?" ) { $sev=0; } else { $sev=$junk[0]; }
				$diff_totals[$sev]++ ;
				#print "$result_string[$diff_job]\n";
			}
		} #end if making DMP and TXT files at all
	NextFile:
	} # next file

	if ( $DiffFiles eq "True" && $diff_job > 0 ) {
		my $label;
		if ( $MOVE == 1 ) { close MOVE_FILES; }
		print SYNTAX "END DATA.\n";
		print SYNTAX "SAVE TRANSLATE /TYPE=ODBC\n";
		print SYNTAX " /CONNECT='DSN=BACKEND_TEST_RESULTS;UID=db2v91i1;PWD=Pass1234;IpAddress=9.30.83.207;TcpPort=50000;Database=STATS001'\n";
		print SYNTAX " /UNENCRYPTED\n /MISSING=IGNORE\n /TABLE='SPSS_TEMP'\n";
		print SYNTAX " /KEEP=BUILD, PLATFORM, TEST_CASE, TEST_SUITE, TEST_RESULT, TEST_DATE, LANGUAGE\n";
		print SYNTAX " /SQL='INSERT INTO DB2V91I1.\"BACKEND_TEST_RESULTS\" (\"BUILD\", \"PLATFORM\", \"TEST_CASE\", '+\n";
		print SYNTAX " '\"TEST_SUITE\", \"TEST_RESULT\", \"TEST_DATE\", \"LANGUAGE\") SELECT \"BUILD\", \"PLATFORM\", '+\n";
		print SYNTAX " '\"TEST_CASE\", \"TEST_SUITE\", \"TEST_RESULT\", \"TEST_DATE\", \"LANGUAGE\" FROM SPSS_TEMP'\n";
		print SYNTAX " /SQL='DROP TABLE \"SPSS_TEMP\"'.\n";

		my @results = sort @result_string;
		my $i = 0;
		my $total_width=$max_name_width+28;
		my $r=RepeatChar ($total_width,'-');
		my $grand_total = 0;
		my $pct = 0;

		open( SUMMARY, ">", $summary_file) or die "Problem with summary file ( $summary_file ): $!" ;
		if ( lc($summary_file) =~ ".txt" ) {
			printf SUMMARY "Summary file created on $datestring\nBaselines from $baselinedir.\nComparison is from $comparisondir.\nDetails of file differences are in $diffdir.\n";
			printf SUMMARY "$r\n";
			printf SUMMARY "%-8s", "Severity";
			printf SUMMARY "%2s", "  ";
			printf SUMMARY "%-".$max_name_width."s", "File";
			printf SUMMARY "%2s", "  ";
			printf SUMMARY "%-70s", "Results";
			printf SUMMARY "%2s", "  ";
			printf SUMMARY "%-8s\n", "Diffs";
			printf SUMMARY "$r\n";
			foreach my $index (1 .. $#results) {
				my @args = ( split ":", $results[$index], 4 ) ;
				next if ( $REPORT_UNDIFFABLE eq "NO" && $args[3] eq '?' ); # May only want files that are diffed
				printf SUMMARY "%-8s", $args[0];
				printf SUMMARY "%2s", "  ";
				printf SUMMARY "%-".$max_name_width."s", $args[1];
				printf SUMMARY "%2s", "  ";
				printf SUMMARY "%-70s", $args[2];
				printf SUMMARY "%2s", "  ";
				printf SUMMARY "%-8s\n", $args[3];
			}
			for ($i = 0; $i <= $SEV_MAX; $i++) { $grand_total = $grand_total + $diff_totals[$i] }
			printf SUMMARY "$r\n\n";
			printf SUMMARY "Diff totals\n";
			$r=RepeatChar (36,'-');
			printf SUMMARY "$r\n";
			printf SUMMARY "%-12s","Severity";
			printf SUMMARY "%-12s","N";
			printf SUMMARY "%-12s\n","Percent";
			printf SUMMARY "$r\n";
			for ($i = 0; $i <= $SEV_MAX; $i++) {
				$pct = ($diff_totals[$i] * 100) / $grand_total ;
				if ( $i eq 0 ) { $label = "Problem"; }
				if ( $i eq 1 ) { $label = "Identical"; }
				if ( $i eq 2 ) { $label = "Virtually Identical"; }
				if ( $i eq 3 ) { $label = "Virtually Identical"; }
				if ( $i eq 4 ) { $label = "Not Identical"; }
				if ( $i eq 5 ) { $label = "Not diffed (too different)"; }
				printf SUMMARY "%-10s", "$label";
				printf SUMMARY "%2s", "  ";
				printf SUMMARY "%-10d", $diff_totals[$i];
				printf SUMMARY "%2s", "  ";
				printf SUMMARY "%8.2f\n", $pct;
			}
			printf SUMMARY "$r\n";
			printf SUMMARY "%-12s", "TOTAL:";
			printf SUMMARY "%-8d\n", "$grand_total";
			printf SUMMARY "$r\n";
			if ( $diff_totals[0] > 0 ) {
				printf SUMMARY "Severity 0 indicates that there was some kind of error in diffing.\nThe most likely cause is that either the baseline or comparison file was not found.\nCheck these files individually.\n";
			}
			close SUMMARY;
		} else {
			#------------------------- BEGIN HTML
			printf SUMMARY "<!DOCTYPE html><html>";
			printf SUMMARY "<head><title>Summary file created on $datestring</title>";
			printf SUMMARY "<style>table,th,td{border:\1px solid black;border-style:solid;border-width:1px;}</style>";
			printf SUMMARY "</head>";
			printf SUMMARY "<body>";
			printf SUMMARY "<p style=\"text-align:left\">Baselines from <a href=\"file:///$baselinedir\">$baselinedir</a>.<br>Comparison is from <a href=\"file:///$comparisondir\">$comparisondir</a>.<br>Details of file differences are in <a href=\"file:///$diffdir\">$diffdir</a>.</p>";
			printf SUMMARY "<p style=\"font-size:20px\">Results</p>";
			printf SUMMARY "<div class=\"itemBody\">";
			printf SUMMARY "<table><tbody>";
			printf SUMMARY "<tr>";
			printf SUMMARY "<th align=\"center\">Severity</th>";
			printf SUMMARY "<th align=\"center\">File</th>";
			printf SUMMARY "<th align=\"center\">Results</th>";
			printf SUMMARY "<th align=\"center\">Diffs</th>";
			printf SUMMARY "</tr>";
			foreach my $index (1 .. $#results) {
				my @args = ( split ":", $results[$index], 4 ) ;
				next if ( $REPORT_UNDIFFABLE eq "NO" && $args[3] eq '?' ); # May only want files that are diffed
				printf SUMMARY "<td align=\"right\">$args[0]</td>";
				if ( $args[0] > 3 ) {
					# FOR EXAMPLE: <a href="http://www.w3schools.com">This is a link</a>
					my $href="file:///$diffdir/$args[1].dif";
					printf SUMMARY "<td align=\"right\"><a href=\"$href\">$args[1]</a></td>";
				} else {
					printf SUMMARY "<td align=\"right\">$args[1]</a></td>";
				}
				printf SUMMARY "<td align=\"right\">$args[2]</td>";
				printf SUMMARY "<td align=\"right\">$args[3]</td></tr>";
			}
			printf SUMMARY "</tbody></table></div>";
			printf SUMMARY "<div class=\"itemBody\">";
			printf SUMMARY "<p style=\"font-size:20px\">Diff Totals</p>";
			printf SUMMARY "<table><tbody>";
			printf SUMMARY "<tr>";
			printf SUMMARY "<th align=\"center\">Severity</th>";
			printf SUMMARY "<th align=\"center\">N</th>";
			printf SUMMARY "<th align=\"center\">Percent</th>";
			printf SUMMARY "</tr #end d>";
			$grand_total=0;
			my $explanation;
			for ($i = 0; $i <= $SEV_MAX; $i++) { $grand_total = $grand_total + $diff_totals[$i] }
			for ($i = 0; $i <= $SEV_MAX; $i++) {
				$pct = ($diff_totals[$i] * 100) / $grand_total ;
				if ( $i eq 0 ) { $label = "Problem"; }
				if ( $i eq 1 ) { $label = "Identical"; }
				if ( $i eq 2 ) { $label = "Virtually Identical"; }
				if ( $i eq 3 ) { $label = "Virtually Identical"; }
				if ( $i eq 4 ) { $label = "Not Identical"; }
				if ( $i eq 5 ) { $label = "Not diffed (too different)"; }
				printf SUMMARY "<td align=\"right\">$label</td>";
				printf SUMMARY "<td align=\"right\">$diff_totals[$i]</td>";
				printf SUMMARY "<td align=\"right\">$pct</td></tr>";
				}	
			printf SUMMARY "<td>TOTAL:</td>";
			printf SUMMARY "<td>$grand_total</td></tr>";
			printf SUMMARY "</tbody></table></div>";
			if ( $diff_totals[0] > 0 ) {
				printf SUMMARY "<p style=\"text-align:left\">Severity 0 indicates that there was some kind of error in diffing.<br>The most likely cause is that either the baseline or comparison file was not found.<br>Check these files individually.</p>"; }
				printf SUMMARY "</body></html>";
			#------------------------- END HTML
			}
		close SUMMARY;
	} # end diffing
NextLanguage:
} # next language

close SYNTAX;
$datestring = localtime();
SendToOutput($LOGFILE,"Job finished: ".$datestring,"log");
exit 0;
